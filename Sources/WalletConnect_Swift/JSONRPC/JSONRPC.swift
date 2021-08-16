// 

import Foundation

protocol JSONConvertible where Self: Encodable {
    func json() throws -> String
}

extension JSONConvertible  {
    func json() throws -> String {
        let data = try JSONEncoder().encode(self)
        guard let string = String(data: data, encoding: .utf8) else {
            throw DataConversionError.dataToStringFailed
        }
        return string
    }
}

enum DataConversionError: Error {
    case stringToDataFailed
    case dataToStringFailed
}

struct JSONRPCError: Error, Codable {
    let code: Int
    let message: String
}

struct JSONRPCRequest<T: Codable>: Codable {
    let id: Int64
    let jsonrpc: String
    let method: ClientSynchMethod
    let params: T
    
    enum CodingKeys: CodingKey {
        case id
        case jsonrpc
        case method
        case params
    }
    
    private static func generateId() -> Int64 {
        return Int64(Date().timeIntervalSince1970) * 1000
    }
}

extension JSONRPCRequest where T == ClientSynchParams {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        method = try container.decode(ClientSynchMethod.self, forKey: .method)
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
