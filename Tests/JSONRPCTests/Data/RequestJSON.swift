// MARK: - Valid Request Data

enum RequestJSON {

    static let paramsByPosition = """
{
    "jsonrpc": "2.0",
    "method": "request",
    "params": [
        69,
        "0xdeadbeef",
        true
    ],
    "id": 1
}
""".data(using: .utf8)!

    static let paramsByName = """
{
    "jsonrpc": "2.0",
    "method": "request",
    "params": {
        "number": 69,
        "string": "0xdeadbeef",
        "bool": true
    },
    "id": 1
}
""".data(using: .utf8)!

    static let emptyParamsByPosition = """
{
    "jsonrpc": "2.0",
    "method": "request",
    "params": [],
    "id": 1
}
""".data(using: .utf8)!

    static let emptyParamsByName = """
{
    "jsonrpc": "2.0",
    "method": "request",
    "params": {},
    "id": 1
}
""".data(using: .utf8)!

    static let paramsOmitted = """
{
    "jsonrpc": "2.0",
    "method": "request",
    "id": 1
}
""".data(using: .utf8)!

    static let withStringIdentifier = """
{
    "jsonrpc": "2.0",
    "method": "request",
    "params": {
        "number": 69
    },
    "id": "a1b2c3d4e5f6"
}
""".data(using: .utf8)!

    static let notification = """
{
    "jsonrpc": "2.0",
    "method": "notification",
    "params": {
        "number": 69
    }
}
""".data(using: .utf8)!

    static let notificationWithoutParams = """
{
    "jsonrpc": "2.0",
    "method": "notification"
}
""".data(using: .utf8)!
}

// MARK: - Invalid Request Data

enum InvalidRequestJSON {

    static let badVersion = """
{
    "jsonrpc": "1.0",
    "method": "request",
    "params": {
        "number": 69
    },
    "id": 1
}
""".data(using: .utf8)!

    static let intPrimitiveParams = """
{
    "jsonrpc": "2.0",
    "method": "request",
    "params": 420,
    "id": 1
}
""".data(using: .utf8)!

    static let stringPrimitiveParams = """
{
    "jsonrpc": "2.0",
    "method": "request",
    "params": "0xdeadbeef",
    "id": 1
}
""".data(using: .utf8)!

    static let boolPrimitiveParams = """
{
    "jsonrpc": "2.0",
    "method": "request",
    "params": true,
    "id": 1
}
""".data(using: .utf8)!
}
