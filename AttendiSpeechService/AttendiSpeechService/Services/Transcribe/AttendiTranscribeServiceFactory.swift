import Foundation

/// Factory for creating instances of `AttendiTranscribeServiceImpl` configured to use the Attendi transcription API.
///
/// This object provides a convenient entry point for clients to instantiate a fully configured
/// `TranscribeService` without needing to manually construct its dependencies. It encapsulates the
/// creation logic and ensures consistent setup of the underlying `AttendiTranscribeServiceImpl`.
///
/// Typical usage:
/// ```
/// let service = AttendiTranscribeServiceFactory.create(apiConfig:)
/// ```
public enum AttendiTranscribeServiceFactory {

    /// Creates a new instance of `AttendiTranscribeServiceImpl` with the provided configuration.
    ///
    /// - Parameters:
    ///   - apiConfig: Configuration for accessing the Attendi transcription API.
    ///   - reportId: Optional custom report ID. If not provided, a random UUID will be generated.
    /// - Returns: A fully configured `TranscribeService` implementation.
    public static func create(
        apiConfig: AttendiTranscribeAPIConfig,
        reportId: String = UUID().uuidString
    ) -> TranscribeService {
        return AttendiTranscribeServiceImpl(
            apiConfig: apiConfig,
            reportId: reportId
        )
    }
}
