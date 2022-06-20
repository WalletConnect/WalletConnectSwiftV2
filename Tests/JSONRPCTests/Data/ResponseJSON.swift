// MARK: - Valid Response Data

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

    static let arrayResult = """
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": [
        "very", "array", "wow"
    ]
}
""".data(using: .utf8)!

    static let objectResult = """
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": {
        "int": 0,
        "string": "0xc0ffee",
        "bool": false
    }
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

    static let plainError = """
{
    "jsonrpc": "2.0",
    "error": {
        "code": -32600,
        "message": "Invalid Request"
    },
    "id": 0
}
""".data(using: .utf8)!

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

    static let errorWithPrimitiveData = """
{
    "jsonrpc": "2.0",
    "error": {
        "code": -32600,
        "message": "Invalid Request",
        "data": "much data wow"
    },
    "id": 0
}
""".data(using: .utf8)!

    static let errorWithStructuredData = """
{
    "jsonrpc": "2.0",
    "error": {
        "code": -32600,
        "message": "Invalid Request",
        "data": [
            69,
            true,
            "please don't use heterogeneus arrays :("
        ]
    },
    "id": 0
}
""".data(using: .utf8)!
}

// MARK: - Invalid Response Data

enum InvalidResponseJSON {

    static let ambiguousResult = """
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": true,
    "error": {
        "code": -32600,
        "message": "Invalid Request"
    }
}
""".data(using: .utf8)!

    static let absentResult = """
{
    "id": 1,
    "jsonrpc": "2.0"
}
""".data(using: .utf8)!

    static let badVersion = """
{
    "id": 1,
    "jsonrpc": "1.0",
    "result": true
}
""".data(using: .utf8)!

    static let successWithoutIdentifier = """
{
    "jsonrpc": "2.0",
    "result": true
}
""".data(using: .utf8)!
}
