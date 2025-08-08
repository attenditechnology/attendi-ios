import Foundation

/// A plugin that sends recorded audio to a backend transcription API for synchronous speech-to-text processing.
///
/// `AttendiSyncTranscribePlugin` captures raw audio frames during a recording session, encodes them,
/// and sends the encoded audio to a transcription service once recording stops. It is designed for use
/// with synchronous (blocking) transcription services where the entire audio must be captured
/// before transcription can begin.
///
/// Use this plugin when you want to automatically transcribe user speech after they finish speaking,
/// such as in short-form interactions (e.g. form inputs, commands, or voice notes).
///
/// - Hooks into the `AttendiRecorderModel` lifecycle:
///   - Clears audio buffer before recording starts.
///   - Collects audio frames while recording.
///   - Triggers transcription upon stopping.
/// - Notifies the caller using the provided callbacks:
///   - `onStartRecording` — called when recording begins.
///   - `onTranscribeStarted` — called when transcription starts (after recording ends).
///   - `onTranscribeCompleted` — called with the resulting transcript or an error upon completion.
///
/// - Note: This plugin stores audio frames in memory for the duration of a recording session.
///         It is best suited for short to moderate-length recordings.
///
/// - Parameters:
///   - service: A service implementation that communicates with a transcription backend.
///   - audioEncoder: Responsible for encoding raw PCM audio into the format required by the API.
///   - onStartRecording: Callback invoked when the recording task is started.
///   - onTranscribeStarted: Callback invoked when the transcription task is started.
///   - onTranscribeCompleted: Callback invoked when the transcription completes.
///     Provides either the transcribed text or an error if the transcription failed.
public final class AttendiSyncTranscribePlugin: AttendiRecorderPlugin {

    private let service: TranscribeService
    private let audioEncoder: TranscribeAudioEncoder
    private let onStartRecording: () -> Void
    private let onTranscribeStarted: () -> Void
    private let onTranscribeCompleted: (_ transcript: String?, _ error: Error?) -> Void

    private var audioFrames: [Int16] = []

    public init(
        service: TranscribeService,
        audioEncoder: TranscribeAudioEncoder = AttendiTranscribeAudioEncoderFactory.create(),
        onStartRecording : @escaping () -> Void = {},
        onTranscribeStarted: @escaping () -> Void = {},
        onTranscribeCompleted: @escaping (_ transcript: String?, _ error: Error?) -> Void
    ) {
        self.service = service
        self.audioEncoder = audioEncoder
        self.onStartRecording = onStartRecording
        self.onTranscribeStarted = onTranscribeStarted
        self.onTranscribeCompleted = onTranscribeCompleted
    }

    public func activate(model: AttendiRecorderModel) async {
        await model.onBeforeStartRecording { [weak self] in
            guard let self else { return }
            audioFrames.removeAll()
        }

        await model.onStartRecording { [weak self] in
            guard let self else { return }
            onStartRecording()
        }

        await model.onAudio { [weak self] audioFrame in
            guard let self else { return }
            audioFrames.append(contentsOf: audioFrame.samples)
        }

        await model.onStopRecording { [weak self, weak model] in
            guard let self, let model else { return }
            onTranscribeStarted()
            do {
                let audioFrames = audioFrames
                let encodedAudio = try await audioEncoder.encode(audioSamples: audioFrames)
                let transcript = try await service.transcribe(audioEncoded: encodedAudio)
                onTranscribeCompleted(transcript, nil)
            } catch {
                onTranscribeCompleted(nil, error)
                await model.callbacks.invokeOnError(error)
            }
            audioFrames.removeAll()
        }
    }
}
