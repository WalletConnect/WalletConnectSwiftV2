

import Foundation

struct RequestSubscriptionPayload: Codable {
    let topic: String
    let request: ChatRequest
}
