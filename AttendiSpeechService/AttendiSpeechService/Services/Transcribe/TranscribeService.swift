import Foundation

/// Protocol for communicating with a synchronous transcription API.
///
/// Implementations of this protocol handle the process of sending encoded audio data
/// to the backend and returning the resulting transcription text.
///
/// This service is typically used for single-shot transcriptions where the entire
/// audio input is available up front, as opposed to real-time streaming.
public protocol TranscribeService {

    /// Sends the provided encoded audio data to a transcription API and
    /// returns the transcribed text, if available.
    ///
    /// - Parameter audioEncoded: Base64-encoded audio data, typically in a supported PCM format.
    /// - Returns: The transcription result as a string, or `nil` if transcription failed or no text was returned.
    func transcribe(audioEncoded: String) async throws -> String
}
