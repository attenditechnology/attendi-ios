import Foundation

/// Default implementation of `TranscribeAudioEncoder` provided by the Attendi SDK.
///
/// This encoder transforms raw PCM audio data into a base64-encoded string,
/// which is the expected format for Attendi's transcription API.
///
/// Consumers may use this implementation as-is, or replace it with a custom encoder
/// if a different format or preprocessing step is required.
final class AttendiTranscribeAudioEncoder: TranscribeAudioEncoder {

    /// Encodes raw PCM audio samples into a Base64-encoded string.
    ///
    /// - Parameter audioSamples: The raw PCM audio samples as `[Int16]`.
    /// - Returns: A Base64-encoded `String` representation of the audio data.
    func encode(audioSamples: [Int16]) async throws -> String {
        let byteArray = AudioEncoder.shortsToData(shorts: audioSamples)
        return byteArray.base64EncodedString()
    }
}
