import Commons

public typealias ID = Either<String, Int>

/**
 TODO: Add documentation
 */
public struct RPCRequest: Codable {
    
//    public static var defaultIdentifierGenerator: IdentifierGenerator
    
    public let jsonrpc: String
    
    public let method: String
    
    public let params: AnyCodable
    
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
