import Commons
@testable import JSONRPC

extension Either where L == String, R == Int {
    
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
