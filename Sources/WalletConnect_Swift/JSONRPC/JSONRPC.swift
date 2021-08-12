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

struct JSONRPCRequest<T: Codable>: Encodable, JSONConvertible {
    let id: Int64 = Self.generateId()
    let jsonrpc = "2.0"
    let method: String
    let params: T
    
    private static func generateId() -> Int64 {
        return Int64(Date().timeIntervalSince1970) * 1000
    }
}

struct JSONRPCResponse<T: Codable>: Codable {
    let jsonrpc = "2.0"
    let id: Int64
    let result: T

    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case id
        case result
        case error
    }

    init(id: Int64, result: T) {
        self.id = id
        self.result = result
    }
}

struct JSONRPCErrorResponse: Codable {
    let jsonrpc = "2.0"
    let id: Int64
    let error: JSONRPCError
}

extension JSONRPCResponse {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(result, forKey: .result)
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let error = try values.decodeIfPresent(JSONRPCError.self, forKey: .error) {
            throw error
        }
        self.id = try values.decode(Int64.self, forKey: .id)
        self.result = try values.decode(T.self, forKey: .result)
    }
}


