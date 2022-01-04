
import Foundation
import WalletConnectUtils

public struct JsonRpcRecord: Codable {
    let id: Int64
    let topic: String
    let request: Request
    var response: JsonRpcResponseTypes?
    
    struct Request: Codable {
        let method: String
        let params: AnyCodable
    }
}

