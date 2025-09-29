import Foundation

/// Factory struct for creating instances of `AttendiAsyncTranscribeServiceImpl`.
public struct AttendiAsyncTranscribeServiceFactory {

    /// Constructs a default implementation of `AsyncTranscribeService` using the provided `apiConfig`.
    ///
    /// This service manages the WebSocket connection, authentication, and audio streaming.
    ///
    /// - Parameters
    ///   - apiConfig: Configuration for authentication and endpoint setup.
    ///   - accessToken: Optional pre-obtained access token. If provided, it will be used directly for authentication
    ///     instead of requesting a new token from the authentication service.
    /// - Returns: A fully configured instance of `AsyncTranscribeService`.
    public static func create(
        apiConfig: AttendiTranscribeAPIConfig,
        accessToken: String? = nil
    ) -> AsyncTranscribeService {
        return AttendiAsyncTranscribeServiceImpl(
            apiConfig: apiConfig,
            authenticationService: AttendiAuthenticationServiceImpl(),
            accessToken: accessToken
        )
    }
}
