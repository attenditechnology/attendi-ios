import Foundation

/// Default WebSocket-based implementation of `AsyncTranscribeService` used for real-time speech-to-text transcription
/// with the Attendi backend.
///
/// This class establishes and manages a bi-directional WebSocket connection to stream audio data
/// and receive transcription updates in real time. It handles the entire session lifecycle, including:
/// - Authentication via `AttendiAuthenticationService` (if an access token is not provided).
/// - Connection initialization using a JSON configuration message.
/// - Streaming encoded audio data.
/// - Receiving intermediate and final transcription messages.
/// - Graceful shutdown via end-of-stream signaling.
/// - Error propagation for connection, authentication, or decoding failures.
///
/// Consumers can use this class directly or implement their own version of `AsyncTranscribeService`
/// if they require a custom transport or different protocol handling.
///
/// - Parameters:
///   - apiConfig: The API configuration required to connect to the Attendi backend, including endpoint and model.
///   - authenticationService: The service used to acquire an access token if one is not provided directly.
///   - accessToken: Optional bearer token used for authenticating the WebSocket connection. If nil, the
///     service will fetch one using the provided `authenticationService`.
class AttendiAsyncTranscribeServiceImpl: BaseAsyncTranscribeService {

    /// WebSocket endpoint path for calling the Attendi transcribe async service.
    private static let websocketEndpoint = "v1/speech/transcribe/stream"

    private let apiConfig: AttendiTranscribeAPIConfig
    private let authenticationService: AttendiAuthenticationService
    private let accessToken: String?
    
    init(
        apiConfig: AttendiTranscribeAPIConfig,
        authenticationService: AttendiAuthenticationService,
        accessToken: String? = nil
    ) {
        self.apiConfig = apiConfig
        self.authenticationService = authenticationService
        self.accessToken = accessToken
        super.init()
    }
    
    override func createWebSocketRequest() async throws -> URLRequest {
        let token: String
        if let accessToken = accessToken {
            token = accessToken
        } else {
            token = try await authenticationService.authenticate(apiConfig: apiConfig)
        }
        return try createAttendiWebSocketRequest(accessToken: token)
    }
    
    override func onRetryAttempt(
        retryAttempt: Int,
        previousRequest: URLRequest?,
        error: Error?
    ) async throws -> URLRequest {
        let token = try await authenticationService.authenticate(apiConfig: apiConfig)
        return try createAttendiWebSocketRequest(accessToken: token)
    }
    
    override func getOpenMessage() -> String {
        return AttendiAsyncTranscribeServiceMessages.initialConfiguration()
    }
    
    override func getCloseMessage() -> String {
        return AttendiAsyncTranscribeServiceMessages.close()
    }
    
    private func createAttendiWebSocketRequest(accessToken: String) throws -> URLRequest {
        let urlComponents = URLComponents(string: getWebSocketURL())

        guard let url = urlComponents?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }
    
    private func getWebSocketURL() -> String {
        return "\(apiConfig.webSocketBaseURL)/\(Self.websocketEndpoint)"
    }
}
