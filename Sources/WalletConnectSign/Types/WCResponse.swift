import Foundation
import WalletConnectUtils

struct WCResponse: Codable {
    let topic: String
    let chainId: String?
    let requestMethod: WCRequest.Method
    let requestParams: WCRequest.Params
    let result: JsonRpcResult

    var timestamp: Date {
        return JsonRpcID.timestamp(from: result.id)
    }
}
