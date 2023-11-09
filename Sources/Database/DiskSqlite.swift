import Foundation
import SQLite3

public final class DiskSqlite: Sqlite {

    private let path: String

    private var db: OpaquePointer?

    private let lock = UnfairLock()

    public init(path: String) {
        self.path = path
    }

    public func openDatabase() throws {
        try lock.locked {
            guard sqlite3_open_v2(path, &db, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
                throw SQLiteError.openDatabase(path: path)
            }
        }
    }

    public func query<Row: SqliteRow>(sql: String) throws -> [Row] {
        return try lock.locked {
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
    }

    public func execute(sql: String) throws {
        try lock.locked {
            var error: UnsafeMutablePointer<CChar>?
            guard sqlite3_exec(db, sql, nil, nil, &error) == SQLITE_OK else {
                let message = error.map { String(cString: $0) }
                throw SQLiteError.exec(error: message)
            }
        }
    }

    public func closeConnection() {
        lock.locked {
            sqlite3_close(db)
        }
    }
}
