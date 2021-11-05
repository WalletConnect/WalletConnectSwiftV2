
import Foundation

struct JSONRPCErrorResponse: Error, Equatable, Codable {
    public let jsonrpc = "2.0"
    public let id: Int64
    public let error: JSONRPCErrorResponse.Error

    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case id
        case error
    }

    public init(id: Int64, error: JSONRPCErrorResponse.Error) {
        self.id = id
        self.error = error
    }
    struct Error: Codable, Equatable {
        let code: Int
        let message: String
    }
}
