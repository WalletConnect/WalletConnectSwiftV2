import Commons
@testable import JSONRPC

final class TestIdentifierGenerator: IdentifierGenerator {

    var id: RPCID = .right(Int64.random())

    func next() -> RPCID {
        return id
    }
}

extension Either where L == String, R == Int64 {

    var isString: Bool {
        left != nil
    }

    var isNumber: Bool {
        right != nil
    }
}

extension JSONRPCError {
    static func stub(data: AnyCodable? = nil) -> JSONRPCError {
        JSONRPCError(code: Int.random(), message: String.random(), data: data)
    }
}
