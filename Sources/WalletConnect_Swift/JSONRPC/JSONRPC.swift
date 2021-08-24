// 

import Foundation

protocol JSONConvertible where Self: Encodable {
    func json() throws -> String
}

extension Encodable  {
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
    let method: String
    let params: T
    
    enum CodingKeys: CodingKey {
        case id
        case jsonrpc
        case method
        case params
    }
    
    init(method: String, params: T) {
        self.id = JSONRPCRequest.generateId()
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
    }

    private static func generateId() -> Int64 {
        return Int64(Date().timeIntervalSince1970) * 1000
    }
}

