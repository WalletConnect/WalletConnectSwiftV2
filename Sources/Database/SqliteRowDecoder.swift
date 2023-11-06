import Foundation
import SQLite3

public class SqliteRowDecoder {

    private let statement: OpaquePointer?

    init(statement: OpaquePointer?) {
        self.statement = statement
    }

    /// Decode string from column at index
    /// - Parameter index: Column index
    /// - Returns: Decoded string
    public func decodeString(at index: Int32) throws -> String {
        guard let raw = sqlite3_column_text(statement, index) else {
            throw SQLiteError.decodeString(index: index)
        }
        return String(cString: raw)
    }

    /// Decode bool from column at index
    /// - Parameter index: Column index
    /// - Returns: Decoded bool
    public func decodeBool(at index: Int32) throws -> Bool {
        let string = try decodeString(at: index)
        return (string as NSString).boolValue
    }

    /// Decode codable object from column at index
    /// - Parameter index: Column index
    /// - Returns: Decoded codable object
    public func decodeCodable<T: Codable>(at index: Int32) throws -> T {
        let string = try decodeString(at: index)
        guard let data = Data(base64Encoded: string) else {
            throw SQLiteError.stringIsNotBase64
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Decode date from column at index
    /// - Parameter index: Column index
    /// - Returns: Decoded date
    public func decodeDate(at index: Int32) throws -> Date {
        let string = try decodeString(at: index)
        guard let interval = TimeInterval(string) else {
            throw SQLiteError.stringIsNotTimestamp
        }
        return Date(timeIntervalSince1970: interval)
    }
}
