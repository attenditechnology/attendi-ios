import Foundation

/// A contract for decoding raw text-based messages (typically JSON) into domain-level actions.
///
/// This protocol allows SDK consumers to customize how messages received from a real-time
/// connection (e.g. WebSocket) are interpreted and transformed into `TranscribeAsyncAction` objects.
///
/// Use this protocol when you need to plug in your own decoder logic to handle custom JSON response structures.
///
/// This is useful when the backend response does not match the expected default shape and you want to
/// deserialize it into your own data classes using `Decodable`.
///
/// ### Example:
/// Suppose your server returns a JSON payload like:
///
/// ```json
/// {
///   "payload": {
///     "actions": [...]
///   }
/// }
/// ```
///
/// You can decode this structure by defining your own codable data classes that match the nested JSON:
///
/// ```swift
/// struct CustomPayloadResponse: Decodable {
///   let payload: CustomPayloadWrappedResponse
/// }
///
/// struct CustomPayloadWrappedResponse: Decodable {
///   let actions: [TranscribeAsyncAnnotationResponse]
/// }
/// ```
///
/// Then, you can use your own deserialization logic (e.g., via `JSONDecoder().decode(CustomPayloadResponse.self, from: data)`)
/// to extract the data as needed.
///
/// This gives you full control over how the response is interpreted and mapped to your models.
public protocol AsyncTranscribeMessageDecoder {
    
    /// Decodes a raw message string into a list of `TranscribeAsyncAction` objects.
    ///
    /// - Parameter response: The raw string message, typically received from a connection listener.
    /// - Returns: A list of parsed `TranscribeAsyncAction`s. May be empty if the message doesn't map to any action.
    /// - Throws: An error if decoding fails. Implementations should clearly document failure modes.
    func decode(_ response: String) throws -> [TranscribeAsyncAction]
} 
