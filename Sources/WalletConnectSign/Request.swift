import Foundation
import WalletConnectUtils

public struct Request: Codable, Equatable {
    public let id: Int64
    public let topic: String
    public let method: String
    public let params: AnyCodable
    public let chainId: Blockchain

    internal init(id: Int64, topic: String, method: String, params: AnyCodable, chainId: Blockchain) {
        self.id = id
        self.topic = topic
        self.method = method
        self.params = params
        self.chainId = chainId
    }

    public init(topic: String, method: String, params: AnyCodable, chainId: Blockchain) {
        self.id = JsonRpcID.generate()
        self.topic = topic
        self.method = method
        self.params = params
        self.chainId = chainId
    }
}
