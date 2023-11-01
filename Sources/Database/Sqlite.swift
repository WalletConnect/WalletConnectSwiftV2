import Foundation
import SQLite3

public protocol Sqlite {

    /// Opening A New Database Connection
    func openDatabase() throws

    /// Evaluate an SQL Statement
    /// - Parameter sql: SQL query
    /// - Returns: Table rows array
    func query<Row: SqliteRow>(sql: String) throws -> [Row]

    /// One-Step query execution
    /// - Parameter sql: SQL query
    func execute(sql: String) throws

    /// Closing A Database Connection
    func closeConnection()
}
