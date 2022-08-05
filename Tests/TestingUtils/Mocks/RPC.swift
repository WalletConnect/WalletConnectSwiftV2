import JSONRPC

public extension RPCRequest {

    static func stub() -> RPCRequest {
        RPCRequest(method: "method", params: EmptyCodable())
    }

    static func stub(method: String, id: Int64) -> RPCRequest {
        RPCRequest(method: method, params: EmptyCodable(), id: id)
    }
}
