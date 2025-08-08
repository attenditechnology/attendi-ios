import Foundation
import AttendiSpeechService

enum ExampleAttendiTranscribeAPI {

    static let transcribeAPIConfig = AttendiTranscribeAPIConfig(
        apiBaseURL: "https://sandbox.api.attendi.nl",
        webSocketBaseURL: "wss://sandbox.api.attendi.nl",
        customerKey: Bundle.main.object(forInfoDictionaryKey: "ATTENDI_CUSTOMER_KEY") as! String,
        userId: "userId",
        unitId: "unitId",
        userAgent: "iOS",
        modelType: "DistrictCare"
    )
}
