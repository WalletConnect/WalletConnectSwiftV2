
import Foundation
import WalletConnectUtils

struct ChatResponse: Codable {
    let topic: String
    let requestMethod: ChatRequest.Method
    let requestParams: ChatRequest.Params
    let result: JsonRpcResult
}

