import Commons

public typealias ID = Either<String, Int>

/**
 TODO: Add documentation
 */
public struct RPCRequest: Codable {
    
//    public static var defaultIdentifierGenerator: IdentifierGenerator
    
    public let jsonrpc: String
    
    public let method: String
    
    public let params: AnyCodable? // must be structured value, MAY be omitted
    
    public let id: ID?
    
    internal init<C>(method: String, params: C, id: ID?) where C: Codable {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = AnyCodable(params)
        self.id = id
    }
}

extension RPCRequest {
    
    static func notification<C>(method: String, params: C) -> RPCRequest where C: Codable {
        return RPCRequest(method: method, params: params, id: nil)
    }
}

extension RPCRequest {
    
    public var isNotification: Bool {
        return id == nil
    }
}

extension RPCRequest {
    
//    enum CodingKeys: CodingKey {
//        case jsonrpc
//        case method
//        case params
//        case id
//    }
    
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
    
//    public func encode(to encoder: Encoder) throws {
//
//    }
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
