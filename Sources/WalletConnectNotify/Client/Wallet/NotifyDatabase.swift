import Foundation
import Database

final class NotifyDatabase {

    enum Table {
        static let subscriptions = "NotifySubscription"
    }

    private let appGroup: String
    private let database: String
    private let sqlite: Sqlite

    init(appGroup: String, database: String, sqlite: Sqlite) {
        self.appGroup = appGroup
        self.database = database
        self.sqlite = sqlite

        prepareDatabase()
    }

    func save(subscription: NotifySubscription) throws {
        try sqlite.openDatabase(path: path)
        defer { sqlite.closeConnection() }

        let sql = SqliteQuery.replace(table: Table.subscriptions, row: subscription)
        try sqlite.execute(sql: sql)

        sqlite.closeConnection()
    }

    func getSubscription(topic: String) throws -> NotifySubscription? {
        try sqlite.openDatabase(path: path)
        defer { sqlite.closeConnection() }

        let sql = SqliteQuery.select(table: Table.subscriptions)
        let subscriptions: [NotifySubscription] = try sqlite.query(sql: sql)
        return subscriptions.first(where: { $0.topic == topic })
    }
}

private extension NotifyDatabase {

    var path: String {
        guard let path = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent(database) else {

            fatalError("Database path not exists")
        }

        return path.absoluteString
    }

    func prepareDatabase() {
        defer { sqlite.closeConnection() }
        try? sqlite.openDatabase(path: path)
        try? sqlite.execute(sql: """
            CREATE TABLE NotifySubscription (
                topic TEXT PRIMARY KEY,
                account TEXT NOT NULL,
                relay TEXT NOT NULL,
                metadata TEXT NOT NULL,
                scope TEXT NOT NULL,
                expiry TEXT NOT NULL,
                symKey TEXT NOT NULL
            );
        """)
    }
}
