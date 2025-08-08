import AVFoundation

/// Factory object for creating instances of `AttendiRecorderImpl`.
public enum AttendiRecorderFactory {

    /// Creates a new `AttendiRecorder` instance with optional configuration and plugin support.
    ///
    /// By default:
    /// - Uses a new instance of `AudioRecordingConfig` with default parameters.
    /// - Delegates to `AudioRecorderFactory.create()` to obtain the default low-level recorder.
    /// - Attaches no plugins unless explicitly provided.
    ///
    /// - Parameters:
    ///    - audioRecordingConfig: Configuration for audio format, sample rate, etc. Defaults to a new instance of `AudioRecordingConfig`.
    ///    - recorder: The low-level `AudioRecorder` implementation to use. Defaults to `AudioRecorderFactory.create()`.
    ///    - plugins: Optional plugins for extending recording behavior (e.g., filters, analytics). Defaults to an empty list.
    /// - Returns: A fully constructed `AttendiRecorder` instance.
    public static func create(
        audioRecordingConfig: AudioRecordingConfig = AudioRecordingConfig(),
        recorder: AudioRecorder = AudioRecorderFactory.create(),
        plugins: [AttendiRecorderPlugin] = []
    ) -> AttendiRecorder {
        AttendiRecorderImpl(
            audioRecordingConfig: audioRecordingConfig,
            recorder: recorder,
            plugins: plugins
        )
    }
}
