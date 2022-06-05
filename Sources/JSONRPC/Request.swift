import Commons

public typealias ID = Either<String, Int>

/**
 TODO: Add documentation
 */
public struct RPCRequest: Equatable {
    
    enum Error: Swift.Error {
        case invalidPrimitiveParameter
    }
    
//    public static var defaultIdentifierGenerator: IdentifierGenerator
    
    public let jsonrpc: String
    
    public let method: String
    
    public let params: AnyCodable?
    
    public let id: ID?
    
    internal init(method: String, params: AnyCodable?, id: ID?) {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
        self.id = id
    }
    
    internal init<C>(method: String, checkedParams params: C, id: ID) throws where C: Codable {
        if params is Int || params is Double || params is String || params is Bool {
            throw Error.invalidPrimitiveParameter
        }
        self.init(method: method, params: AnyCodable(params), id: id)
    }
    
    public init<C>(method: String, checkedParams params: C, id: Int) throws where C: Codable {
        try self.init(method: method, checkedParams: params, id: .right(id))
    }

    public init<C>(method: String, checkedParams params: C, id: String) throws where C: Codable {
        try self.init(method: method, checkedParams: params, id: .left(id))
    }

    public init<C>(method: String, params: C, id: Int) where C: Codable {
        self.init(method: method, params: AnyCodable(params), id: .right(id))
    }

    public init<C>(method: String, params: C, id: String) where C: Codable {
        self.init(method: method, params: AnyCodable(params), id: .left(id))
    }
    
    public init(method: String, id: Int) {
        self.init(method: method, params: nil, id: .right(id))
    }
    
    public init(method: String, id: String) {
        self.init(method: method, params: nil, id: .left(id))
    }
}

extension RPCRequest {
    
    static func notification<C>(method: String, params: C) -> RPCRequest where C: Codable {
        return RPCRequest(method: method, params: AnyCodable(params), id: nil)
    }
    
    static func notification(method: String) -> RPCRequest {
        return RPCRequest(method: method, params: nil, id: nil)
    }
}

extension RPCRequest {
    
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
        id = try container.decodeIfPresent(ID.self, forKey: .id)
        method = try container.decode(String.self, forKey: .method)
        params = try container.decodeIfPresent(AnyCodable.self, forKey: .params)
        if let decodedParams = params {
            if decodedParams.value is Int || decodedParams.value is Double || decodedParams.value is String || decodedParams.value is Bool {
                throw DecodingError.dataCorruptedError(
                    forKey: .params,
                    in: container,
                    debugDescription: "")
            }
        }
    }
}

// ----------------------------------------------------------------------------
// TODO: String convertible



protocol RPCRequestConvertible {
    func asRPCRequest() -> RPCRequest
}

// ID gen
import Foundation

protocol IdentifierGenerator {
    func next() -> ID
}

struct StringIdentifierGenerator: IdentifierGenerator {
    
    func next() -> ID {
        return ID(UUID().uuidString.replacingOccurrences(of: "-", with: ""))
    }
}

struct IntIdentifierGenerator: IdentifierGenerator {
    
    func next() -> ID {
        return ID(Int.random(in: Int.min...Int.max))
    }
}
