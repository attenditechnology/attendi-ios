import Foundation

/// Response returned from the transcription API containing the result.
struct AttendiTranscribeResponse: Decodable {
    let transcript: String
}
