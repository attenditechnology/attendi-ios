import Foundation

/// Factory struct for creating instances of `AttendiAsyncTranscribeServiceImpl`.
public struct AttendiAsyncTranscribeServiceFactory {

    /// Constructs a default implementation of `AsyncTranscribeService` using the provided `apiConfig`.
    ///
    /// This service manages the WebSocket connection, authentication, and audio streaming.
    ///
    /// - Parameter apiConfig: Configuration for authentication and endpoint setup.
    /// - Returns: A fully configured instance of `AsyncTranscribeService`.
    public static func create(apiConfig: AttendiTranscribeAPIConfig) -> AsyncTranscribeService {
        return AttendiAsyncTranscribeServiceImpl(
            apiConfig: apiConfig,
            authenticationService: AttendiAuthenticationServiceImpl()
        )
    }
}
