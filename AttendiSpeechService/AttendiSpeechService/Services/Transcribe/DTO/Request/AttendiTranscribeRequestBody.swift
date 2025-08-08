import Foundation

/// Requests to Attendi's transcribe-like APIs usually require the same base request body.
struct AttendiTranscribeRequestBody: Encodable {
    let audio: String
    let userId: String
    let unitId: String
    let metadata: AttendiTranscribeRequestMetadata
    let config: AttendiTranscribeRequestConfig
}

struct AttendiTranscribeRequestMetadata: Encodable {
    let userAgent: String
    let reportId: String
}

struct AttendiTranscribeRequestConfig: Encodable {
    let model: String
}
