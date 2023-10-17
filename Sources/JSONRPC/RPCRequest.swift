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
    
    public let topic: String?

    internal init(method: String, params: AnyCodable?, id: RPCID?, topic: String? = nil) {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
        self.id = id
        self.topic = topic
    }

    internal init<C>(method: String, checkedParams params: C, id: RPCID, topic: String?) throws where C: Codable {
        if params is Int || params is Double || params is String || params is Bool {
            throw Error.invalidPrimitiveParameter
        }
        self.init(method: method, params: AnyCodable(params), id: id, topic: topic)
    }

    public init<C>(method: String, checkedParams params: C, idGenerator: IdentifierGenerator = defaultIdentifierGenerator, topic: String?) throws where C: Codable {
        try self.init(method: method, checkedParams: params, id: idGenerator.next(), topic: topic)
    }

    public init<C>(method: String, checkedParams params: C, id: Int64, topic: String?) throws where C: Codable {
        try self.init(method: method, checkedParams: params, id: .right(id), topic: topic)
    }

    public init<C>(method: String, checkedParams params: C, id: String, topic: String?) throws where C: Codable {
        try self.init(method: method, checkedParams: params, id: .left(id), topic: topic)
    }

    public init<C>(method: String, params: C, idGenerator: IdentifierGenerator = defaultIdentifierGenerator, topic: String?) where C: Codable {
        self.init(method: method, params: AnyCodable(params), id: idGenerator.next(), topic: topic)
    }

    public init<C>(method: String, params: C, id: Int64, topic: String?) where C: Codable {
        self.init(method: method, params: AnyCodable(params), id: .right(id), topic: topic)
    }

    public init<C>(method: String, params: C, rpcid: RPCID, topic: String?) where C: Codable {
        self.init(method: method, params: AnyCodable(params), id: rpcid, topic: topic)
    }

    public init<C>(method: String, params: C, id: String, topic: String?) where C: Codable {
        self.init(method: method, params: AnyCodable(params), id: .left(id), topic: topic)
    }

    public init(method: String, idGenerator: IdentifierGenerator = defaultIdentifierGenerator, topic: String?) {
        self.init(method: method, params: nil, id: idGenerator.next(), topic: topic)
    }

    public init(method: String, id: Int64, topic: String?) {
        self.init(method: method, params: nil, id: .right(id), topic: topic)
    }

    public init(method: String, id: String, topic: String?) {
        self.init(method: method, params: nil, id: .left(id), topic: topic)
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
        topic = try container.decodeIfPresent(String.self, forKey: .topic)
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
