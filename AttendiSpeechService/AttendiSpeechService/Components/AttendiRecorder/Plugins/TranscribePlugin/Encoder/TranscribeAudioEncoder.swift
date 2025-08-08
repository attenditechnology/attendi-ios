import Foundation

/// Protocol defining the contract for encoding raw audio data before it is sent
/// to a transcription backend.
///
/// The encoder transforms a list of raw PCM audio samples `[Int16]` into a `String`
/// representation—typically base64 or another transport-safe format—suitable for transmission over the network.
///
/// This abstraction allows SDK consumers to provide custom encoding strategies
/// (e.g., compression or encryption) by supplying their own implementation.
public protocol TranscribeAudioEncoder {
    /// Encodes an array of PCM audio samples into a string format suitable for API transmission.
    ///
    /// - Parameter audioSamples: The raw audio samples (e.g., from the microphone) to be encoded.
    /// - Returns: A `String` containing the encoded audio payload.
    /// - Throws: An error if encoding fails or the input is invalid.
    func encode(audioSamples: [Int16]) async throws -> String
}
