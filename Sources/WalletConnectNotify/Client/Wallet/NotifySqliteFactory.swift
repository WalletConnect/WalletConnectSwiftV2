import Foundation

struct NotifySqliteFactory {

    static func create(appGroup: String) -> Sqlite {
        let databasePath = databasePath(appGroup: appGroup, database: "notify_v\(version).db")
        let sqlite = DiskSqlite(path: databasePath)
        return sqlite
    }

    static func databasePath(appGroup: String, database: String) -> String {
        guard let path = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent(database) else {

            fatalError("Database path not exists")
        }

        return path.absoluteString
    }

    static var version: String {
        return "1"
    }
}
