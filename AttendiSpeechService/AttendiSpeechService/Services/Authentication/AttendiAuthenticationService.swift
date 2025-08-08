import Foundation

/// Interface defining the contract for authenticating with Attendi's backend services.
///
/// Implementations of this interface are responsible for retrieving a valid access token
/// that can be used to authorize API requests.
public protocol AttendiAuthenticationService {

    /// Authenticates with the Attendi backend using the provided `apiConfig` and returns
    /// a valid bearer token.
    ///
    /// - Parameter apiConfig: The configuration object containing credentials, client ID, or any other information needed to authenticate with the API.
    /// - returns: A valid access token to be used in subsequent API or WebSocket requests.
    /// - throws: Exception if the authentication fails or the response is invalid.
    func authenticate(apiConfig: AttendiTranscribeAPIConfig) async throws -> String
}
