/**
 TODO: Add documentation
 */
public struct RPCRequest: Equatable {

    enum Error: Swift.Error {
        case invalidPrimitiveParameter
    }

    public static var defaultIdentifierGenerator: IdentifierGenerator = IntIdentifierGenerator()

    public let jsonrpc: String

    public let method: String

    public let params: AnyCodable?

    public let id: RPCID?

    internal init(method: String, params: AnyCodable?, id: RPCID?) {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
        self.id = id
    }

    internal init<C>(method: String, checkedParams params: C, id: RPCID) throws where C: Codable {
        if params is Int || params is Double || params is String || params is Bool {
            throw Error.invalidPrimitiveParameter
        }
        self.init(method: method, params: AnyCodable(params), id: id)
    }

    public init<C>(method: String, checkedParams params: C, idGenerator: IdentifierGenerator = defaultIdentifierGenerator) throws where C: Codable {
        try self.init(method: method, checkedParams: params, id: idGenerator.next())
    }

    public init<C>(method: String, checkedParams params: C, id: Int64) throws where C: Codable {
        try self.init(method: method, checkedParams: params, id: .right(id))
    }

    public init<C>(method: String, checkedParams params: C, id: String) throws where C: Codable {
        try self.init(method: method, checkedParams: params, id: .left(id))
    }

    public init<C>(method: String, params: C, idGenerator: IdentifierGenerator = defaultIdentifierGenerator) where C: Codable {
        self.init(method: method, params: AnyCodable(params), id: idGenerator.next())
    }

    public init<C>(method: String, params: C, id: Int64) where C: Codable {
        self.init(method: method, params: AnyCodable(params), id: .right(id))
    }

    public init<C>(method: String, params: C, rpcid: RPCID) where C: Codable {
        self.init(method: method, params: AnyCodable(params), id: rpcid)
    }

    public init<C>(method: String, params: C, id: String) where C: Codable {
        self.init(method: method, params: AnyCodable(params), id: .left(id))
    }

    public init(method: String, idGenerator: IdentifierGenerator = defaultIdentifierGenerator) {
        self.init(method: method, params: nil, id: idGenerator.next())
    }

    public init(method: String, id: Int64) {
        self.init(method: method, params: nil, id: .right(id))
    }

    public init(method: String, id: String) {
        self.init(method: method, params: nil, id: .left(id))
    }
}

extension RPCRequest {

    public static func notification<C>(method: String, params: C) -> RPCRequest where C: Codable {
        return RPCRequest(method: method, params: AnyCodable(params), id: nil)
    }

    public static func notification(method: String) -> RPCRequest {
        return RPCRequest(method: method, params: nil, id: nil)
    }

    public var isNotification: Bool {
        return id == nil
    }
}

extension RPCRequest: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        guard jsonrpc == "2.0" else {
            throw DecodingError.dataCorruptedError(
                forKey: .jsonrpc,
                in: container,
                debugDescription: "The JSON-RPC protocol version must be exactly \"2.0\".")
        }
        id = try container.decodeIfPresent(RPCID.self, forKey: .id)
        method = try container.decode(String.self, forKey: .method)
        params = try container.decodeIfPresent(AnyCodable.self, forKey: .params)
        if let decodedParams = params {
            if decodedParams.value is Int || decodedParams.value is Double || decodedParams.value is String || decodedParams.value is Bool {
                throw DecodingError.dataCorruptedError(
                    forKey: .params,
                    in: container,
                    debugDescription: "The params member cannot be a primitive value, it must be an array or an object.")
            }
        }
    }
}

// TODO: String convertible to help logging
