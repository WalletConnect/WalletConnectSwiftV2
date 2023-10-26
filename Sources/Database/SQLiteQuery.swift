import Foundation

public struct SqliteQuery {

    public static func replace(table: String, row: SqliteRow) -> String {
        let encoder = row.encode()

        let arguments = encoder.values
            .map { $0.argument }
            .joined(separator: ", ")

        let values = encoder.values
            .map { $0.value }
            .joined(separator: ", ")

        return """
            REPLACE INTO \(table) (\(arguments))
            VALUES (\(values))
        """
    }

    public static func select(table: String) -> String {
        return "SELECT * FROM \(table)"
    }
}
