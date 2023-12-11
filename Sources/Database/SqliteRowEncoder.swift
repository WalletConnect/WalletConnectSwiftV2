import Foundation

public struct SqliteRowEncoder {
    struct Value {
        let argument: String
        let value: String
    }

    var values: [Value] = []

    public init() { }

    public mutating func encodeString(_ value: String, for argument: String) {
        let value = Value(argument: argument, value: value)
        values.append(value)
    }

    public mutating func encodeDate(_ value: Date, for argument: String) {
        let value = Value(argument: argument, value: String(value.timeIntervalSince1970))
        values.append(value)
    }

    public mutating func encodeCodable<T: Codable>(_ value: T, for argument: String) {
        let data = try! JSONEncoder().encode(value)
        let value = Value(argument: argument, value: data.base64EncodedString())
        values.append(value)
    }

    public mutating func encodeBool(_ value: Bool, for argument: String) {
        let value = Value(argument: argument, value: String(value))
        values.append(value)
    }
}
