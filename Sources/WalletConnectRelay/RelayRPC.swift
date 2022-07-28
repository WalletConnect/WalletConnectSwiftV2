import JSONRPC

protocol RPCMethod {
    associatedtype Parameters
    var method: String { get }
    var params: Parameters { get }
}

protocol RelayRPC: RPCMethod {}

extension RelayRPC where Parameters: Codable {

    var idGenerator: IdentifierGenerator {
        return WalletConnectRPCID()
    }

    func wrapToIridium() -> PrefixDecorator<Self> {
        return PrefixDecorator(rpcMethod: self, prefix: "iridium")
//        return PrefixDecorator.iridium(rpcMethod: self)
    }

    func asRPCRequest() -> RPCRequest {
        RPCRequest(method: self.method, params: self.params, idGenerator: self.idGenerator)
    }
}

struct PrefixDecorator<T>: RelayRPC where T: RelayRPC {

    typealias Parameters = T.Parameters

    let rpcMethod: T
    let prefix: String

    var method: String {
        "\(prefix)_\(rpcMethod.method)"
    }

    var params: Parameters {
        rpcMethod.params
    }
}


// TODO: Move
import Foundation

struct WalletConnectRPCID: IdentifierGenerator {

    func next() -> RPCID {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000) * 1000
        let random = Int64.random(in: 0..<1000)
        return .right(Int(timestamp + random))
    }
}
