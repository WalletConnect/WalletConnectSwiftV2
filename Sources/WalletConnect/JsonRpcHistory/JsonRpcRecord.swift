

import Foundation
import WalletConnectUtils

struct JsonRpcRecord: Codable {
    let id: Int64
    let topic: String
    let request: Request
    var response: JsonRpcResponseTypes?
    let chainId: String?

    struct Request: Codable {
        let method: WCRequest.Method
        let params: WCRequest.Params
    }
}

