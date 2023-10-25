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
}
