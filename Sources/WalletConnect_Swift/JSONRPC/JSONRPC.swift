// 

import Foundation

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

