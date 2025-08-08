import Foundation

/// Default implementation of `AttendiAuthenticationService` provided by the Attendi SDK.
///
/// This implementation knows how to communicate with Attendi's backend to obtain
/// a valid access token for transcription-related services.
public final class AttendiAuthenticationServiceImpl: AttendiAuthenticationService {

    /// Authenticate endpoint path for calling the Attendi authenticate service.
    private static let authenticateEndpoint = "v1/identity/authenticate"

    public func authenticate(apiConfig: AttendiTranscribeAPIConfig) async throws -> String {
        let authenticateRequest = AttendiAuthenticationRequestBody(
            userId: apiConfig.userId,
            unitId: apiConfig.unitId,
            userAgent: apiConfig.userAgent
        )

        let token = try await authenticate(
            requestBody: authenticateRequest,
            customerKey: apiConfig.customerKey,
            apiBaseURL: apiConfig.apiBaseURL
        )
        return token
    }

    /// Request an authentication token from Attendi's identity service.
    /// If the request is successful, the token is returned. Otherwise, `null` is returned.
    private func authenticate(
        requestBody: AttendiAuthenticationRequestBody,
        customerKey: String,
        apiBaseURL: String
    ) async throws -> String {
        guard let url = URL(string: "\(apiBaseURL)/\(Self.authenticateEndpoint)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; utf-8", forHTTPHeaderField: "Content-Type")
        /// Use the customer key to authenticate the request
        request.setValue(customerKey, forHTTPHeaderField: "x-api-key")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 200 {
            let decodedResponse = try JSONDecoder().decode(AttendiAuthenticationResponse.self, from: data)
            return decodedResponse.token
        }

        throw NSError(domain: String(describing: Self.self), code: -1, userInfo: [NSLocalizedDescriptionKey: "No token received"])
    }
}
