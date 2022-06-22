import Foundation

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

    public init(id: Int64 = JsonRpcID.generate(), method: String, params: T) {
        self.id = id
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
    }
}
