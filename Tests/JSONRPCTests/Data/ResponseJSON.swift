enum ResponseJSON {
    
    // MARK: - Success Responses
    
    static let intResult = """
{
    "jsonrpc": "2.0",
    "result": 69,
    "id": 1
}
""".data(using: .utf8)!
    
    static let doubleResult = """
{
    "jsonrpc": "2.0",
    "result": 3.14159265,
    "id": 1
}
""".data(using: .utf8)!
    
    static let stringResult = """
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": "0xdeadbeef"
}
""".data(using: .utf8)!
    
    static let boolResult = """
{
    "jsonrpc": "2.0",
    "result": true,
    "id": 1
}
""".data(using: .utf8)!
    
    static let withStringIdentifier = """
{
    "jsonrpc": "2.0",
    "result": true,
    "id": "0xdeadbeef"
}
""".data(using: .utf8)!
    
    // MARK: - Error Responses
    
    static let errorWithExplicitNullIdentifier = """
{
    "jsonrpc": "2.0",
    "error": {
        "code": -32600,
        "message": "Invalid Request"
    },
    "id": null
}
""".data(using: .utf8)!
    
    static let errorWithImplicitNullIdentifier = """
{
    "jsonrpc": "2.0",
    "error": {
        "code": -32600,
        "message": "Invalid Request"
    }
}
""".data(using: .utf8)!
}
