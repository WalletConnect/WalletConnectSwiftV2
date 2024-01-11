import Foundation
import Database
import Combine

final class NotifyDatabase {

    enum Table {
        static let subscriptions = "NotifySubscription"
        static let messages = "NotifyMessage"
    }

    private let sqlite: Sqlite
    private let logger: ConsoleLogging

    var onSubscriptionsUpdate: (() throws -> Void)?
    var onMessagesUpdate: (() throws -> Void)?

    init(sqlite: Sqlite, logger: ConsoleLogging) {
        self.sqlite = sqlite
        self.logger = logger

        prepareDatabase()
    }

    // MARK: - NotifySubscriptions

    func save(subscription: NotifySubscription) throws {
        try save(subscriptions: [subscription])
    }

    func save(subscriptions: [NotifySubscription]) throws {
        guard let sql = SqliteQuery.replace(table: Table.subscriptions, rows: subscriptions) else { return }
        try execute(sql: sql)
        try onSubscriptionsUpdate?()
    }

    func replace(subscriptions: [NotifySubscription]) throws {
        try execute(sql: SqliteQuery.delete(table: Table.subscriptions))
        if let sql = SqliteQuery.replace(table: Table.subscriptions, rows: subscriptions) {
            try execute(sql: sql)
        }
        try onSubscriptionsUpdate?()
    }

    func getSubscription(topic: String) -> NotifySubscription? {
        let sql = SqliteQuery.select(table: Table.subscriptions, where: "topic", equals: topic)
        let subscriptions: [NotifySubscription]? = try? query(sql: sql)
        return subscriptions?.first
    }

    func getAllSubscriptions() -> [NotifySubscription] {
        let sql = SqliteQuery.select(table: Table.subscriptions)
        let subscriptions: [NotifySubscription]? = try? query(sql: sql)
        return subscriptions ?? []
    }

    func getSubscriptions(account: Account) -> [NotifySubscription] {
        let sql = SqliteQuery.select(table: Table.subscriptions, where: "account", equals: account.absoluteString)
        let subscriptions: [NotifySubscription]? = try? query(sql: sql)
        return subscriptions ?? []
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

    // MARK: - NotifyMessageRecord

    func getAllMessages() -> [NotifyMessageRecord] {
        let sql = SqliteQuery.select(table: Table.messages)
        let messages: [NotifyMessageRecord]? = try? query(sql: sql)
        return messages ?? []
    }

    func getMessages(topic: String) -> [NotifyMessageRecord] {
        let sql = SqliteQuery.select(table: Table.messages, where: "topic", equals: topic)
        let messages: [NotifyMessageRecord]? = try? query(sql: sql)
        return messages ?? []
    }

    func deleteMessages(topic: String) throws {
        let sql = SqliteQuery.delete(table: Table.messages, where: "topic", equals: topic)
        try execute(sql: sql)
        try onMessagesUpdate?()
    }

    func deleteMessage(id: String) throws {
        let sql = SqliteQuery.delete(table: Table.messages, where: "id", equals: id)
        try execute(sql: sql)
        try onMessagesUpdate?()
    }

    func save(message: NotifyMessageRecord) throws {
        try save(messages: [message])
    }

    func save(messages: [NotifyMessageRecord]) throws {
        guard let sql = SqliteQuery.replace(table: Table.messages, rows: messages) else { return }
        try execute(sql: sql)
        try onMessagesUpdate?()
    }
}

private extension NotifyDatabase {

    func prepareDatabase() {
        do {
            defer { sqlite.closeConnection() }
            try sqlite.openDatabase()
            
            try sqlite.execute(sql: """
                CREATE TABLE IF NOT EXISTS \(Table.subscriptions) (
                    topic TEXT NOT NULL,
                    account TEXT NOT NULL,
                    relay TEXT NOT NULL,
                    metadata TEXT NOT NULL,
                    scope TEXT NOT NULL,
                    expiry TEXT NOT NULL,
                    symKey TEXT NOT NULL,
                    appAuthenticationKey TEXT NOT NULL,
                    id TEXT PRIMARY KEY
                );
            """)

            try sqlite.execute(sql: """
                CREATE TABLE IF NOT EXISTS \(Table.messages) (
                    id TEXT PRIMARY KEY,
                    topic TEXT NOT NULL,
                    title TEXT NOT NULL,
                    body TEXT NOT NULL,
                    icon TEXT NOT NULL,
                    url TEXT NOT NULL,
                    type TEXT NOT NULL,
                    publishedAt TEXT NOT NULL
                );
            """)

            logger.debug("SQlite database created")
        } catch {
            logger.error("SQlite database creation error: \(error.localizedDescription)")
        }
    }

    func execute(sql: String) throws {
        try sqlite.openDatabase()
        defer { sqlite.closeConnection() }

        try sqlite.execute(sql: sql)
    }

    func query<T: SqliteRow>(sql: String) throws -> [T] {
        try sqlite.openDatabase()
        defer { sqlite.closeConnection() }

        return try sqlite.query(sql: sql)
    }
}
