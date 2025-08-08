import Foundation

/// Bundles up the information necessary to communicate with Attendi's speech understanding APIs.
public struct AttendiTranscribeAPIConfig {

    public init(
        apiBaseURL: String = "https://api.attendi.nl",
        webSocketBaseURL: String = "wss://api.attendi.nl",
        customerKey: String,
        userId: String,
        unitId: String,
        userAgent: String? = nil,
        modelType: String? = nil
    ) {
        self.apiBaseURL = apiBaseURL
        self.webSocketBaseURL = webSocketBaseURL
        self.customerKey = customerKey
        self.userId = userId
        self.unitId = unitId
        self.userAgent = userAgent
        self.modelType = modelType
    }

    /// URL of the Attendi Speech Service API, e.g. `https://api.attendi.nl`
    public let apiBaseURL: String

    /// URL of the Attendi WebSocket Service API, e.g. `wss://api.attendi.nl`
    public let webSocketBaseURL: String

    /// Your customer API key.
    public let customerKey: String

    /// Unique id assigned (by you) to your user
    public let userId: String

    /// Unique id assigned (by you) to the team or location of your user.
    public let unitId: String

    /// User agent string identifying the user device, OS and browser.
    public let userAgent: String?

    /// Which model to use, e.g. "ResidentialCare".
    public let modelType: String?
}
