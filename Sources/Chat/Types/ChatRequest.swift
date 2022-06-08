
import Foundation
import WalletConnectUtils

struct ChatRequest: Codable {
    let id: Int64
    let jsonrpc: String
    let method: Method
    let params: Params
    
    enum CodingKeys: CodingKey {
        case id
        case jsonrpc
        case method
        case params
    }
    
    internal init(id: Int64 = generateId(), jsonrpc: String = "2.0", params: Params) {
        self.id = id
        self.jsonrpc = jsonrpc
        self.params = params
        switch params {
        case .invite(_):
            self.method = Method.invite
        case .message(_):
            self.method = Method.message
        }
    }
    
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        method = try container.decode(Method.self, forKey: .method)
        switch method {
        case .invite:
            let paramsValue = try container.decode(InviteParams.self, forKey: .params)
            params = .invite(paramsValue)
        case .message:
            let paramsValue = try container.decode(String.self, forKey: .params)
            params = .message(paramsValue)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(method.rawValue, forKey: .method)
        switch params {
        case .message(let params):
            try container.encode(params, forKey: .params)
        case .invite(let params):
            try container.encode(params, forKey: .params)
        }
    }
    
    private static func generateId() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)*1000 + Int64.random(in: 0..<1000)
    }
}

extension ChatRequest {
    enum Method: String, Codable {
        case invite = "wc_chatInvite"
        case message = "wc_chatMessage"
    }
}
extension ChatRequest {
    enum Params: Codable {
        case invite(InviteParams)
        case message(String)
    }
}
