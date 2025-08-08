import AVFoundation

/// Default implementation of `AudioRecorder` that handles low-level audio recording operations.
///
/// Designed as a singleton via `shared` to maintain a single recording session at a time,
/// preventing conflicts and improving control over resource management.
final class AudioRecorderImpl: AudioRecorder {
    
    /// Shared singleton instance for centralized audio recording control.
    static let shared: AudioRecorder = AudioRecorderImpl()
    
    private init() { }
    
    /// The underlying audio engine used to manage the audio graph and record audio.
    private var audioEngine: AVAudioEngine?
    
    /// A mutex that ensures thread-safe start/stop of the recording session.
    private let startStopMutex = AsyncMutex()
    
    /// Reference to the microphone input node from which audio data is captured.
    private var inputNode: AVAudioInputNode?
    
    /// Continuation for the audio frame processing stream.
    /// Used to push new audio frames into an `AsyncStream` for sequential processing.
    private var audioFrameContinuation: AsyncStream<AudioFrame>.Continuation?
    
    /// Task that processes audio frames sequentially.
    /// Consumes frames from the `AsyncStream` and invokes the `onAudio` callback for each frame.
    private var audioProcessingTask: Task<Void, Never>?
    
    /// Internal flag indicating whether recording is currently in progress.
    private var isRecordingInternal: Bool = false
    
    func isRecording() async -> Bool {
        isRecordingInternal
    }
    
    func startRecording(
        audioRecordingConfig: AudioRecordingConfig,
        onAudio: @escaping (AudioFrame) async -> Void
    ) async throws {
        try await startStopMutex.withLock {
            if isRecordingInternal {
                throw AudioRecorderError.alreadyRecording
            }

            if await !AudioPermissionVerifier.hasGrantedAudioRecordingPermissions() {
                throw AudioRecorderError.deniedRecodingPermission
            }

            try verifyAudioRecordingConfig(audioRecordingConfig)

            try configureAudioSession(audioRecordingConfig)

            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            
            /// Fetches the current hardware format (may differ from the desired one).
            let format = inputNode.outputFormat(forBus: 0)
            
            /// Define the desired format for resampling (matches app's audio configuration).
            guard let desiredFormat = AVAudioFormat(
                commonFormat: audioRecordingConfig.commonFormat,
                sampleRate: audioRecordingConfig.sampleRate,
                channels: audioRecordingConfig.channel,
                interleaved: audioRecordingConfig.interleaved
            ) else {
                throw AudioRecorderError.unsupportedAudioFormat("Invalid Audio Format")
            }
            
            /// Defensive check: If format reports 0Hz, the input node failed to initialize correctly.
            /// Common cause is AVAudioEngine graph misconfiguration or missing mic permission.
            guard format.sampleRate > 0 else {
                throw AudioRecorderError.unsupportedAudioFormat(
                    "Audio format unsupported: sample rate is 0 Hz. AVAudioEngine inputNode failed to initialize correctly"
                )
            }
            
            self.audioEngine = engine
            self.inputNode = inputNode
            
            /// Creates an AsyncStream for serialized audio frame processing
            let (stream, continuation) = AsyncStream<AudioFrame>.makeStream()
            self.audioFrameContinuation = continuation
            
            /// Create the audio processing task that processes frames sequentially
            let processingTask = Task {
                for await audioFrame in stream {
                    await onAudio(audioFrame)
                }
            }
            self.audioProcessingTask = processingTask
            
            /// Setting same bufferSize as in inputNode.installTap Apple's documention
            let bufferSize: AVAudioFrameCount = 8192
            
            /// Install a tap on the input node to receive audio data in real time.
            /// We use the hardware format for tap, and resample to the desired format.
            setupTap(inputNode: inputNode, format: format, desiredFormat: desiredFormat, bufferSize: bufferSize)
            
            do {
                /// Start the audio engine and begin recording.
                try engine.start()
                isRecordingInternal = true
            } catch {
                await stopRecording()
                throw error
            }
        }
    }

    /// Configures AVAudioSession for audio recording with input and output support.
    private func configureAudioSession(_ audioRecordingConfig: AudioRecordingConfig) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: audioRecordingConfig.categoryOptions)
        try session.setPreferredSampleRate(audioRecordingConfig.sampleRate)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func setupTap(inputNode: AVAudioInputNode, format: AVAudioFormat, desiredFormat: AVAudioFormat, bufferSize: AVAudioFrameCount) {
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { buffer, _ in
            guard let resampleBuffer = AudioEncoder.resampleBuffer(buffer: buffer, from: format, to: desiredFormat) else { return }
            guard let channelData = resampleBuffer.int16ChannelData else { return }
            
            let frameLength = Int(resampleBuffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: channelData.pointee, count: frameLength))
            let audioFrame = AudioFrame(samples: samples)

            /// Send the audio frame to the stream for serialized processing.
            /// This ensures frames are processed in order and prevents race conditions.
            Task {
                self.audioFrameContinuation?.yield(audioFrame)
            }
        }
    }
    
    /// Verifies whether the provided audio configuration is supported by this implementation.
    private func verifyAudioRecordingConfig(_ audioRecordingConfig: AudioRecordingConfig) throws {
        if audioRecordingConfig.channel != 1 {
            throw AudioRecorderError.unsupportedAudioFormat("Currently the only supported audio channel is 1")
        }
        
        if audioRecordingConfig.commonFormat != AVAudioCommonFormat.pcmFormatInt16 {
            throw AudioRecorderError.unsupportedAudioFormat("Currently the only supported audio encoding is AVAudioCommonFormat.pcmFormatInt16")
        }
        
        if audioRecordingConfig.interleaved != false {
            throw AudioRecorderError.unsupportedAudioFormat("Currently only non-interleaved audio samples are supported.")
        }
    }
    
    func stopRecording() async {
        await startStopMutex.withLock {
            if !isRecordingInternal {
                return
            }
            isRecordingInternal = false
            
            inputNode?.removeTap(onBus: 0)
            inputNode = nil
            
            /// Finish the audio frame stream and wait for processing to complete
            audioFrameContinuation?.finish()
            await audioProcessingTask?.value
            
            audioProcessingTask = nil
            audioFrameContinuation = nil
            
            audioEngine?.stop()
            audioEngine = nil
            
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
}
