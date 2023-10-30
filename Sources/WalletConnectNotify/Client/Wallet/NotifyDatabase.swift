import Foundation
import Database
import Combine

final class NotifyDatabase {

    enum Table {
        static let subscriptions = "NotifySubscription"
    }

    private let appGroup: String
    private let database: String
    private let sqlite: Sqlite
    private let logger: ConsoleLogging

    var onSubscriptionsUpdate: (() throws -> Void)?

    init(appGroup: String, database: String, sqlite: Sqlite, logger: ConsoleLogging) {
        self.appGroup = appGroup
        self.database = database
        self.sqlite = sqlite
        self.logger = logger

        prepareDatabase()
    }

    func save(subscription: NotifySubscription) throws {
        try save(subscriptions: [subscription])
    }

    func save(subscriptions: [NotifySubscription]) throws {
        let sql = try SqliteQuery.replace(table: Table.subscriptions, rows: subscriptions)
        try execute(sql: sql)
        try onSubscriptionsUpdate?()
    }

    func getSubscription(topic: String) throws -> NotifySubscription? {
        return try getAllSubscriptions().first(where: { $0.topic == topic })
    }

    func getAllSubscriptions() throws -> [NotifySubscription] {
        let sql = SqliteQuery.select(table: Table.subscriptions)
        return try query(sql: sql)
    }

    func getSubscriptions(account: Account) throws -> [NotifySubscription] {
        return try getAllSubscriptions().filter { $0.account == account }
    }

    func deleteSubscription(topic: String) throws {
        let sql = SqliteQuery.delete(table: Table.subscriptions, where: "topic", equals: topic)
        try execute(sql: sql)
        try onSubscriptionsUpdate?()
    }

    func deleteSubscription(account: Account) throws {
        let sql = SqliteQuery.delete(table: Table.subscriptions, where: "account", equals: account.absoluteString)
        try execute(sql: sql)
        try onSubscriptionsUpdate?()
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
        do {
            defer { sqlite.closeConnection() }
            try sqlite.openDatabase(path: path)
            try sqlite.execute(sql: """
                CREATE TABLE IF NOT EXISTS NotifySubscription (
                    topic TEXT PRIMARY KEY,
                    account TEXT NOT NULL,
                    relay TEXT NOT NULL,
                    metadata TEXT NOT NULL,
                    scope TEXT NOT NULL,
                    expiry TEXT NOT NULL,
                    symKey TEXT NOT NULL,
                    appAuthenticationKey TEXT NOT NULL
                );
            """)
            logger.debug("SQlite database created at path \(path)")
        } catch {
            logger.error("SQlite database creation error: \(error.localizedDescription)")
        }
    }

    func execute(sql: String) throws {
        try sqlite.openDatabase(path: path)
        defer { sqlite.closeConnection() }

        try sqlite.execute(sql: sql)
    }

    func query<T: SqliteRow>(sql: String) throws -> [T] {
        try sqlite.openDatabase(path: path)
        defer { sqlite.closeConnection() }

        return try sqlite.query(sql: sql)
    }
}
