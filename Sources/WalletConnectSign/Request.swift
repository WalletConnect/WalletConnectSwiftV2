import Foundation
import JSONRPC
import WalletConnectUtils

public struct Request: Codable, Equatable {
    public let id: RPCID
    public let topic: String
    public let method: String
    public let params: AnyCodable
    public let chainId: Blockchain

    internal init(id: RPCID, topic: String, method: String, params: AnyCodable, chainId: Blockchain) {
        self.id = id
        self.topic = topic
        self.method = method
        self.params = params
        self.chainId = chainId
    }

    public init(topic: String, method: String, params: AnyCodable, chainId: Blockchain) {
        self.init(id: RPCID(JsonRpcID.generate()), topic: topic, method: method, params: params, chainId: chainId)
    }

    internal init<C>(id: RPCID, topic: String, method: String, params: C, chainId: Blockchain) where C: Codable {
        self.init(id: id, topic: topic, method: method, params: AnyCodable(params), chainId: chainId)
    }
}
