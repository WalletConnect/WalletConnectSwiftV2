import Foundation
import WalletConnectUtils

struct WCRequestSubscriptionPayload: Codable {
    let topic: String
    let wcRequest: WCRequest

    var timestamp: Date {
        return JsonRpcID.timestamp(from: wcRequest.id)
    }
}
