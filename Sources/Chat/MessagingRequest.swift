
import Foundation
import WalletConnectUtils

struct MessagingRequest: Codable {
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
    
    internal init(id: Int64 = generateId(), jsonrpc: String = "2.0", method: Method, params: Params) {
        self.id = id
        self.jsonrpc = jsonrpc
        self.method = method
        self.params = params
    }
    
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        method = try container.decode(Method.self, forKey: .method)
        switch method {
        case .invite:
            let paramsValue = try container.decode(Invite.self, forKey: .params)
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

extension MessagingRequest {
    enum Method: String, Codable {
        case invite = "wc_messaging_invite"
        case message = "wv_messaging_message"
    }
}
extension MessagingRequest {
    enum Params: Codable {
        case invite(Invite)
        case message(String)
    }
}
