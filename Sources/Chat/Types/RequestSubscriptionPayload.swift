

import Foundation
import WalletConnectUtils

struct RequestSubscriptionPayload: Codable {
    let topic: String
    let request: JSONRPCRequest<ChatRequestParams>
}
