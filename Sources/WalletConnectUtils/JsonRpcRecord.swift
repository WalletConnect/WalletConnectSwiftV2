
import Foundation

public struct JsonRpcRecord: Codable {
    public let id: Int64
    public let topic: String
    public let request: Request
    public var response: JsonRpcResponseTypes?
    public let chainId: String?
    
    public struct Request: Codable {
        public let method: String
        public let params: AnyCodable
    }
}

