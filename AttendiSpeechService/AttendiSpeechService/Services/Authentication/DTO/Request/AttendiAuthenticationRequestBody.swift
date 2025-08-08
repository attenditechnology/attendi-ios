import Foundation

struct AttendiAuthenticationRequestBody: Encodable {
    let userId: String
    let unitId: String
    let userAgent: String?
}
