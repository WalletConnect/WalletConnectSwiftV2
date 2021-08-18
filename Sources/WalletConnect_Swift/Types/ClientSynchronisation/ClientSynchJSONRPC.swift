// 

import Foundation


struct ClientSynchJSONRPC: Codable {
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
    
    internal init(id: Int64, jsonrpc: String, method: Method, params: Params) {
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
        case .pairingApprove:
            let paramsValue = try container.decode(PairingApproveParams.self, forKey: .params)
            params = .pairingApprove(paramsValue)
        case .pairingReject:
            let paramsValue = try container.decode(PairingRejectParams.self, forKey: .params)
            params = .pairingReject(paramsValue)
        }
    }
}

extension ClientSynchJSONRPC {
    enum Method: String, Codable {
        case pairingApprove = "wc_pairingApprove"
        case pairingReject = "wc_pairingReject"
    }
}

extension ClientSynchJSONRPC {
    enum Params: Codable, Equatable {
        case pairingApprove(PairingApproveParams)
        case pairingReject(PairingRejectParams)
        
        static func == (lhs: Params, rhs: Params) -> Bool {
            switch (lhs, rhs) {
            case (.pairingApprove(let lhsParam), .pairingApprove(let rhsParam)):
                return lhsParam == rhsParam
            case (.pairingReject(let lhsParam), pairingReject(let rhsParam)):
                return lhsParam == rhsParam
            default:
                return false
            }
        }
        
        init(from decoder: Decoder) throws {
            fatalError("forbidden")
        }
        
        func encode(to encoder: Encoder) throws {
            fatalError("forbidden")
        }
    }
}
