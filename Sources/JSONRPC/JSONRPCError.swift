import Commons

public struct JSONRPCError: Error, Equatable, Codable {
    public let code: Int
    public let message: String
    public let data: AnyCodable?
}



//code    message    meaning
//-32700    Parse error    Invalid JSON was received by the server. //An error occurred on the server while parsing the JSON text.
//-32600    Invalid Request    The JSON sent is not a valid Request object.
//-32601    Method not found    The method does not exist / is not available.
//-32602    Invalid params    Invalid method parameter(s).
//-32603    Internal error    Internal JSON-RPC error.
//-32000 to -32099    Server error    Reserved for implementation-defined server-errors.
