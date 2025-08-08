import Foundation

/// Factory for creating `AsyncTranscribeMessageDecoder` instances.
///
/// This factory provides a centralized way to create decoder instances,
/// allowing for easy configuration and potential future enhancements.
public struct AttendiAsyncTranscribeMessageDecoderFactory {
    
    /// Creates a default `AttendiAsyncTranscribeMessageDecoder` instance.
    ///
    /// - Returns: A configured `AsyncTranscribeMessageDecoder` instance.
    public static func create() -> AsyncTranscribeMessageDecoder {
        AttendiAsyncTranscribeMessageDecoder()
    }
} 
