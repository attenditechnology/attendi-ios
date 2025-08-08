import Foundation

/// Default implementation of `AsyncTranscribeMessageDecoder` provided by the Attendi SDK.
///
/// This decoder is responsible for transforming raw JSON responses received from Attendi's
/// WebSocket-based asynchronous transcription API into a list of high-level `TranscribeAsyncAction`s.
///
/// It delegates the decoding logic to `TranscribeAsyncActionMapper`, which first
/// deserializes the JSON payload into an internal DTO model and then maps it to domain-level
/// actions using `TranscribeAsyncActionMapper`.
///
/// This class is used internally by the Attendi SDK, but consumers may provide a custom
/// implementation of `AsyncTranscribeMessageDecoder` to support different protocols,
/// formats, or business rules.
public struct AttendiAsyncTranscribeMessageDecoder: AsyncTranscribeMessageDecoder {
    
    /// A lenient JSON decoder that safely ignores unknown fields in the payload.
    private let jsonDecoder: JSONDecoder
    
    public init() {
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.keyDecodingStrategy = .useDefaultKeys
    }
    
    /// Decodes a raw JSON response into a list of `TranscribeAsyncAction`s.
    ///
    /// - Parameter response: A raw JSON string received from the WebSocket.
    /// - Returns: A list of parsed `TranscribeAsyncAction`s. May be empty if the response contains no actionable data.
    /// - Throws: A `DecodingError` if the JSON is malformed or does not match the expected schema.
    public func decode(_ response: String) throws -> [TranscribeAsyncAction] {
        guard let data = response.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "Failed to convert response string to data"
            ))
        }
        
        let attendiResponse = try jsonDecoder.decode(TranscribeAsyncResponse.self, from: data)
        return try TranscribeAsyncActionMapper.map(response: attendiResponse)
    }
} 
