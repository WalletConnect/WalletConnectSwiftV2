
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
    
    func jsonRpcRequestRepresentation() -> JSONRPCRequest<AnyCodable> {
        return JSONRPCRequest<AnyCodable>(id: id, method: method.rawValue, params: AnyCodable(params))
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
        case .pairingApprove:
            let paramsValue = try container.decode(PairingType.ApproveParams.self, forKey: .params)
            params = .pairingApprove(paramsValue)
        case .pairingReject:
            let paramsValue = try container.decode(PairingType.RejectParams.self, forKey: .params)
            params = .pairingReject(paramsValue)
        case .pairingUpdate:
            let paramsValue = try container.decode(PairingType.UpdateParams.self, forKey: .params)
            params = .pairingUpdate(paramsValue)
        case .pairingUpgrade:
            let paramsValue = try container.decode(PairingType.UpgradeParams.self, forKey: .params)
            params = .pairingUpgrade(paramsValue)
        case .pairingDelete:
            let paramsValue = try container.decode(PairingType.DeleteParams.self, forKey: .params)
            params = .pairingDelete(paramsValue)
        case .pairingPayload:
            let paramsValue = try container.decode(PairingType.PayloadParams.self, forKey: .params)
            params = .pairingPayload(paramsValue)
        case .pairingPing:
            let paramsValue = try container.decode(PairingType.PingParams.self, forKey: .params)
            params = .pairingPing(paramsValue)
        case .sessionPropose:
            let paramsValue = try container.decode(SessionType.ProposeParams.self, forKey: .params)
            params = .sessionPropose(paramsValue)
        case .sessionApprove:
            let paramsValue = try container.decode(SessionType.ApproveParams.self, forKey: .params)
            params = .sessionApprove(paramsValue)
        case .sessionReject:
            let paramsValue = try container.decode(SessionType.RejectParams.self, forKey: .params)
            params = .sessionReject(paramsValue)
        case .sessionUpdate:
            let paramsValue = try container.decode(SessionType.UpdateParams.self, forKey: .params)
            params = .sessionUpdate(paramsValue)
        case .sessionUpgrade:
            let paramsValue = try container.decode(SessionType.UpgradeParams.self, forKey: .params)
            params = .sessionUpgrade(paramsValue)
        case .sessionDelete:
            let paramsValue = try container.decode(SessionType.DeleteParams.self, forKey: .params)
            params = .sessionDelete(paramsValue)
        case .sessionPayload:
            let paramsValue = try container.decode(SessionType.PayloadParams.self, forKey: .params)
            params = .sessionPayload(paramsValue)
        case .sessionPing:
            let paramsValue = try container.decode(SessionType.PingParams.self, forKey: .params)
            params = .sessionPing(paramsValue)
        case .sessionNotification:
            let paramsValue = try container.decode(SessionType.NotificationParams.self, forKey: .params)
            params = .sessionNotification(paramsValue)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(method.rawValue, forKey: .method)
        switch params {
        case .pairingApprove(let params):
            try container.encode(params, forKey: .params)
        case .pairingReject(let params):
            try container.encode(params, forKey: .params)
        case .pairingUpdate(let params):
            try container.encode(params, forKey: .params)
        case .pairingUpgrade(let params):
            try container.encode(params, forKey: .params)
        case .pairingDelete(let params):
            try container.encode(params, forKey: .params)
        case .pairingPayload(let params):
            try container.encode(params, forKey: .params)
        case .pairingPing(let params):
            try container.encode(params, forKey: .params)
        case .sessionPropose(let params):
            try container.encode(params, forKey: .params)
        case .sessionApprove(let params):
            try container.encode(params, forKey: .params)
        case .sessionReject(let params):
            try container.encode(params, forKey: .params)
        case .sessionUpdate(let params):
            try container.encode(params, forKey: .params)
        case .sessionUpgrade(let params):
            try container.encode(params, forKey: .params)
        case .sessionDelete(let params):
            try container.encode(params, forKey: .params)
        case .sessionPayload(let params):
            try container.encode(params, forKey: .params)
        case .sessionPing(let params):
            try container.encode(params, forKey: .params)
        case .sessionNotification(let params):
            try container.encode(params, forKey: .params)
        }
    }
    
    private static func generateId() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)*1000 + Int64.random(in: 0..<1000)
    }

}
