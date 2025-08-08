import Foundation


/// Default implementation of `TranscribeService` responsible for sending recorded audio
/// to Attendi's synchronous speech-to-text transcription API.
/// This class encapsulates the details of HTTP communication with Attendi's backend,
/// including request formatting and endpoint construction. It uses the provided
/// `AttendiTranscribeAPIConfig` for authentication and base URL configuration.
///
/// - Parameters:
///   - apiConfig: Configuration for accessing the Attendi API (e.g., base URL, credentials).
///   - reportId: Unique identifier for the report being transcribed. Used for backend tracking and association.

public final class AttendiTranscribeServiceImpl: TranscribeService {

    private let apiConfig: AttendiTranscribeAPIConfig
    private let reportId: String

    /// Transcribe endpoint path for calling the Attendi transcribe service.
    private static let transcribeEndpoint = "v1/speech/transcribe"

    public init(
        apiConfig: AttendiTranscribeAPIConfig,
        reportId: String
    ) {
        self.apiConfig = apiConfig
        self.reportId = reportId
    }

    public func transcribe(audioEncoded: String) async throws -> String {
        guard let modelType = apiConfig.modelType else {
            throw NSError(
                domain: "AttendiTranscribeService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No model type provided"]
            )
        }

        let audioTaskRequest = AttendiTranscribeRequestBody(
            audio: audioEncoded,
            userId: apiConfig.userId,
            unitId: apiConfig.unitId,
            metadata: AttendiTranscribeRequestMetadata(
                userAgent: apiConfig.userAgent ?? UserAgentProvider.getUserAgent(),
                reportId: reportId
            ),
            config: AttendiTranscribeRequestConfig(model: modelType)
        )

        return try await transcribe(
            requestBody: audioTaskRequest,
            customerKey: apiConfig.customerKey,
            apiBaseURL: apiConfig.apiBaseURL
        )
    }

    /// Transcribe audio using Attendi's transcribe API.
    private func transcribe(
        requestBody: AttendiTranscribeRequestBody,
        customerKey: String,
        apiBaseURL: String
    ) async throws -> String {
        guard let url = URL(string: "\(apiBaseURL)/\(Self.transcribeEndpoint)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; utf-8", forHTTPHeaderField: "Content-Type")
        /// Use the customer key to authenticate the request.
        request.setValue(customerKey, forHTTPHeaderField: "x-api-key")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 {
            let decodedResponse = try JSONDecoder().decode(AttendiTranscribeResponse.self, from: data)
            return decodedResponse.transcript
        }
        
        throw NSError(domain: String(describing: Self.self), code: -1, userInfo: [NSLocalizedDescriptionKey: "No transcribe received"])
    }
}
