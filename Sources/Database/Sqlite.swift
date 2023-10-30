import Foundation
import SQLite3

public final class Sqlite {

    private var db: OpaquePointer?

    public init() { }

    /// Opening A New Database Connection
    /// - Parameter path: Path to database
    public func openDatabase(path: String) throws {
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            throw SQLiteError.openDatabase(path: path)
        }
        var error: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, "PRAGMA journal_mode=WAL;", nil, nil, &error) == SQLITE_OK else {
            let message = error.map { String(cString: $0) }
            throw SQLiteError.exec(error: message)
        }
    }

    /// Evaluate an SQL Statement
    /// - Parameter sql: SQL query
    /// - Returns: Table rows array
    public func query<Row: SqliteRow>(sql: String) throws -> [Row] {
        var queryStatement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &queryStatement, nil) == SQLITE_OK else {
            throw SQLiteError.queryPrepare(statement: sql)
        }
        var rows: [Row] = []
        while sqlite3_step(queryStatement) == SQLITE_ROW {
            let decoder = SqliteRowDecoder(statement: queryStatement)
            guard let row = try? Row(decoder: decoder) else { continue }
            rows.append(row)
        }
        sqlite3_finalize(queryStatement)
        return rows
    }

    /// One-Step query execution
    /// - Parameter sql: SQL query
    public func execute(sql: String) throws {
        var error: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &error) == SQLITE_OK else {
            let message = error.map { String(cString: $0) }
            throw SQLiteError.exec(error: message)
        }
    }

    /// Closing A Database Connection
    public func closeConnection() {
        sqlite3_close(db)
    }
}
