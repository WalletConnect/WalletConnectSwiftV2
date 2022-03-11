
import Foundation

struct WCRequestSubscriptionPayload: Codable {
    let topic: String
    let wcRequest: WCRequest
}
