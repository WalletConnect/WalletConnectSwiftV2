
protocol RelayRPC: RPCMethod {}

extension RelayRPC where Parameters: Codable {

    var idGenerator: IdentifierGenerator {
        return WalletConnectRPCID()
    }

    func wrapToIRN() -> PrefixDecorator<Self> {
        return PrefixDecorator(rpcMethod: self, prefix: "irn")
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
