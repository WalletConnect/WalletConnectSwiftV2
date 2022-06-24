import Foundation
import WalletConnectUtils

struct ChatResponse: Codable {
    let topic: String
    let requestMethod: String
    let requestParams: ChatRequestParams
    let result: JsonRpcResult
}
