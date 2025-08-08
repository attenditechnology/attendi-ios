import AVFoundation

/// Factory object for creating instances of `AttendiTranscribeAudioEncoder`.
public enum AttendiTranscribeAudioEncoderFactory {

    /// Returns an instance of `TranscribeAudioEncoder`.
    ///
    /// Currently returns the singleton implementation `AttendiTranscribeAudioEncoder`.
    /// This can be extended in the future to support dynamic configuration or multiple encoder strategies.
    public static func create() -> TranscribeAudioEncoder {
        AttendiTranscribeAudioEncoder()
    }
}
