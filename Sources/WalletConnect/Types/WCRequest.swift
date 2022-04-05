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
        case .pairingPing:
            let paramsValue = try container.decode(PairingType.PingParams.self, forKey: .params)
            params = .pairingPing(paramsValue)
        case .sessionPropose:
            let paramsValue = try container.decode(SessionType.ProposeParams.self, forKey: .params)
            params = .sessionPropose(paramsValue)
        case .sessionSettle:
            let paramsValue = try container.decode(SessionType.SettleParams.self, forKey: .params)
            params = .sessionSettle(paramsValue)
        case .sessionUpdate:
            let paramsValue = try container.decode(SessionType.UpdateParams.self, forKey: .params)
            params = .sessionUpdate(paramsValue)
        case .sessionDelete:
            let paramsValue = try container.decode(SessionType.DeleteParams.self, forKey: .params)
            params = .sessionDelete(paramsValue)
        case .sessionRequest:
            let paramsValue = try container.decode(SessionType.RequestParams.self, forKey: .params)
            params = .sessionRequest(paramsValue)
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
        case .sessionPropose(let params):
            try container.encode(params, forKey: .params)
        case .sessionSettle(let params):
            try container.encode(params, forKey: .params)
        case .sessionUpdate(let params):
            try container.encode(params, forKey: .params)
        case .sessionDelete(let params):
            try container.encode(params, forKey: .params)
        case .sessionRequest(let params):
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
        case sessionPropose = "wc_sessionPropose"
        case sessionSettle = "wc_sessionSettle"
        case sessionUpdate = "wc_sessionUpdate"
        case sessionDelete = "wc_sessionDelete"
        case sessionRequest = "wc_sessionRequest"
        case sessionPing = "wc_sessionPing"
        case sessionExtend = "wc_sessionExtend"
        case sessionNotification = "wc_sessionNotification"
    }
}

extension WCRequest {
    enum Params: Codable, Equatable {
        case pairingDelete(PairingType.DeleteParams)
        case pairingPing(PairingType.PingParams)
        case sessionPropose(SessionType.ProposeParams)
        case sessionSettle(SessionType.SettleParams)
        case sessionUpdate(SessionType.UpdateParams)
        case sessionDelete(SessionType.DeleteParams)
        case sessionRequest(SessionType.RequestParams)
        case sessionPing(SessionType.PingParams)
        case sessionExtend(SessionType.ExtendParams)
        case sessionNotification(SessionType.NotificationParams)

        static func == (lhs: Params, rhs: Params) -> Bool {
            switch (lhs, rhs) {
            case (.pairingDelete(let lhsParam), pairingDelete(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionPropose(let lhsParam), sessionPropose(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionSettle(let lhsParam), sessionSettle(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionUpdate(let lhsParam), sessionUpdate(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionDelete(let lhsParam), sessionDelete(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionRequest(let lhsParam), sessionRequest(let rhsParam)):
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
