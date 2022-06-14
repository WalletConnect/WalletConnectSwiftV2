
import Foundation
import WalletConnectUtils

struct ChatResponse: Codable {
    let topic: String
    let requestMethod: String
    let requestParams: ChatRequestParams
    let result: JsonRpcResult
}

extension JSONRPCRequest  {
    init(id: Int64 = JSONRPCRequest.generateId(), params: T) where T == ChatRequestParams? {
        self.id = id
        self.jsonrpc = "2.0"
        switch params {
        case .invite:
            self.method = "invite"
        case .message:
            self.method = "message"
        }
        self.params = params
    }
}
