public struct JSONRPCError: Error, Equatable, Codable {
    public let code: Int
    public let message: String
    public let data: AnyCodable?

    public init(code: Int, message: String, data: AnyCodable? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
}

public extension JSONRPCError {
    static let parseError = JSONRPCError(code: -32700, message: "An error occurred on the server while parsing the JSON text.")
    static let invalidRequest = JSONRPCError(code: -32600, message: "The JSON sent is not a valid Request object.")
    static let methodNotFound = JSONRPCError(code: -32601, message: "The method does not exist / is not available.")
    static let invalidParams = JSONRPCError(code: -32602, message: "Invalid method parameter(s).")
    static let internalError = JSONRPCError(code: -32603, message: "Internal JSON-RPC error.")
}
