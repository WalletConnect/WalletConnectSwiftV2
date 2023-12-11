import Foundation
import SQLite3

public final class MemorySqlite: Sqlite {

    private var db: OpaquePointer?

    public init() throws {
        guard sqlite3_open_v2(":memory:", &db, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            throw SQLiteError.openDatabaseMemory
        }
    }

    public func openDatabase() throws {
        // No op
    }

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

    public func execute(sql: String) throws {
        var error: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &error) == SQLITE_OK else {
            let message = error.map { String(cString: $0) }
            throw SQLiteError.exec(error: message)
        }
    }

    public func closeConnection() {
        // No op
    }
}
