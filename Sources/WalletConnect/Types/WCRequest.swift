import Foundation

struct WCRequest: Codable {
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
        case .pairingDelete:
            let paramsValue = try container.decode(PairingType.DeleteParams.self, forKey: .params)
            params = .pairingDelete(paramsValue)
        case .pairingExtend:
            let paramsValue = try container.decode(PairingType.ExtendParams.self, forKey: .params)
            params = .pairingExtend(paramsValue)
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
        case .sessionSettlement:
            let paramsValue = try container.decode(SessionType.SettlementParams.self, forKey: .params)
            params = .sessionSettlement(paramsValue)
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
        case .sessionExtend:
            let paramsValue = try container.decode(SessionType.ExtendParams.self, forKey: .params)
            params = .sessionExtend(paramsValue)
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
        case .pairingDelete(let params):
            try container.encode(params, forKey: .params)
        case .pairingPing(let params):
            try container.encode(params, forKey: .params)
        case .pairingExtend(let params):
            try container.encode(params, forKey: .params)
        case .sessionPropose(let params):
            try container.encode(params, forKey: .params)
        case .sessionApprove(let params):
            try container.encode(params, forKey: .params)
        case .sessionReject(let params):
            try container.encode(params, forKey: .params)
        case .sessionSettlement(let params):
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
        case .sessionExtend(let params):
            try container.encode(params, forKey: .params)
        case .sessionNotification(let params):
            try container.encode(params, forKey: .params)
        }
    }

    private static func generateId() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)*1000 + Int64.random(in: 0..<1000)
    }

}

extension WCRequest {
    enum Method: String, Codable {
        case pairingDelete = "wc_pairingDelete"
        case pairingPing = "wc_pairingPing"
        case pairingExtend = "wc_pairingExtend"
        case sessionPropose = "wc_sessionPropose"
        case sessionApprove = "wc_sessionApprove"
        case sessionReject = "wc_sessionReject"
        case sessionSettlement = "wc_sessionSettlement" // is this correct? check the signature of the method
        case sessionUpdate = "wc_sessionUpdate"
        case sessionUpgrade = "wc_sessionUpgrade"
        case sessionDelete = "wc_sessionDelete"
        case sessionPayload = "wc_sessionPayload"
        case sessionPing = "wc_sessionPing"
        case sessionExtend = "wc_sessionExtend"
        case sessionNotification = "wc_sessionNotification"
    }
}

extension WCRequest {
    enum Params: Codable, Equatable {
        case pairingDelete(PairingType.DeleteParams)
        case pairingPing(PairingType.PingParams)
        case pairingExtend(PairingType.ExtendParams)
        case sessionPropose(SessionType.ProposeParams)
        case sessionApprove(SessionType.ApproveParams)
        case sessionReject(SessionType.RejectParams)
        case sessionSettlement(SessionType.SettlementParams)
        case sessionUpdate(SessionType.UpdateParams)
        case sessionUpgrade(SessionType.UpgradeParams)
        case sessionDelete(SessionType.DeleteParams)
        case sessionPayload(SessionType.PayloadParams)
        case sessionPing(SessionType.PingParams)
        case sessionExtend(SessionType.ExtendParams)
        case sessionNotification(SessionType.NotificationParams)

        static func == (lhs: Params, rhs: Params) -> Bool {
            switch (lhs, rhs) {
            case (.pairingDelete(let lhsParam), pairingDelete(let rhsParam)):
                return lhsParam == rhsParam
            case (.pairingExtend(let lhsParam), pairingExtend(let rhsParams)):
                return lhsParam == rhsParams
            case (.sessionPropose(let lhsParam), sessionPropose(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionApprove(let lhsParam), sessionApprove(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionReject(let lhsParam), sessionReject(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionUpdate(let lhsParam), sessionUpdate(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionUpgrade(let lhsParam), sessionUpgrade(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionDelete(let lhsParam), sessionDelete(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionPayload(let lhsParam), sessionPayload(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionPing(let lhsParam), sessionPing(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionExtend(let lhsParam), sessionExtend(let rhsParams)):
                return lhsParam == rhsParams
            case (.sessionNotification(let lhsParam), sessionNotification(let rhsParam)):
                return lhsParam == rhsParam
            default:
                return false
            }
        }
    }
}
