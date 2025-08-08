import Foundation

/// Wraps lower-level audio APIs to provide a convenient and asynchronous interface
/// for recording audio from the device.
///
/// This abstraction allows consumers to start and stop audio capture and receive audio frames
/// via an async callback.
public protocol AudioRecorder {
    
    /// Indicates whether the recorder is currently capturing audio.
    func isRecording() async -> Bool
    
    /// Starts recording audio with the given configuration.
    ///
    /// - Parameters:
    ///   - audioRecordingConfig: Configuration for the audio source, including sample rate, channel, and encoding.
    ///   - onAudio: An async closure invoked with each `AudioFrame` containing captured audio samples and metadata.
    ///
    /// This method must only be called when recording is not already in progress.
    /// If called again while recording, it should throw `AudioRecorderError.alreadyRecording` to prevent concurrent usage.
    ///
    /// This method must only be called with a valid `AudioRecordingConfig`. If invalid, it will throw `AudioRecorderException.unsupportedAudioFormat`
    /// to prevent starting the recorder.
    ///
    /// Recording is performed on a background task and audio frames are delivered asynchronously.
    func startRecording(
        audioRecordingConfig: AudioRecordingConfig,
        onAudio: @escaping (AudioFrame) async -> Void
    ) async throws
    
    /// Stops the audio recording if it's currently in progress.
    ///
    /// If recording is not active, this call has no effect. The recorder will release its resources
    /// and cease to invoke further audio callbacks.
    func stopRecording() async
}

public enum AudioRecorderError: Error, LocalizedError {
    case alreadyRecording
    case deniedRecodingPermission
    case unsupportedAudioFormat(_ message: String)
    
    public var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "Recorder is already in use"
        case .deniedRecodingPermission:
            return "Permission to access the device's microphone is denied"
        case .unsupportedAudioFormat(let message):
            return message
        }
    } 
}
