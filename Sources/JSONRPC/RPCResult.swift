import Foundation

public enum RPCResult: Codable, Equatable {
    enum Errors: Error {
        case decoding
    }

    case response(AnyCodable)
    case error(JSONRPCError)

    public var value: Codable {
        switch self {
        case .response(let value):
            return value
        case .error(let value):
            return value
        }
    }

    public init(from decoder: Decoder) throws {
        if let value = try? JSONRPCError(from: decoder) {
            self = .error(value)
        } else if let value = try? AnyCodable(from: decoder) {
            self = .response(value)
        } else {
            throw Errors.decoding
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .error(let value):
            try value.encode(to: encoder)
        case .response(let value):
            try value.encode(to: encoder)
        }
    }
}
