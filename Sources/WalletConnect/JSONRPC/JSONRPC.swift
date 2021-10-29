// 

import Foundation

struct JSONRPCError: Error, Codable, Equatable {
    let code: Int
    let message: String
}

public struct JSONRPCRequest<T: Codable&Equatable>: Codable, Equatable {
    
    public let id: Int64
    public let jsonrpc: String
    public let method: String
    public let params: T
    
    enum CodingKeys: CodingKey {
        case id
        case jsonrpc
        case method
        case params
    }
    
    init(id: Int64 = JSONRPCRequest.generateId(), method: String, params: T) {
        self.id = id
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
    }

    private static func generateId() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)*1000 + Int64.random(in: 0..<1000)
    }
}

public struct JSONRPCResponse<T: Codable&Equatable>: Codable, Equatable {
    public let jsonrpc = "2.0"
    public let id: Int64
    public let result: T

    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case id
        case result
    }

    public init(id: Int64, result: T) {
        self.id = id
        self.result = result
    }
}
