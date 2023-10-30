import Foundation
import Combine

protocol NotifyStoring {
    func getAllSubscriptions() -> [NotifySubscription]
    func getSubscriptions(account: Account) throws -> [NotifySubscription]
    func getSubscription(topic: String) throws -> NotifySubscription?
    func setSubscription(_ subscription: NotifySubscription) throws
    func replaceAllSubscriptions(_ subscriptions: [NotifySubscription]) throws
    func deleteSubscription(topic: String) throws
    func clearDatabase(account: Account) throws
    func updateSubscription(_ subscription: NotifySubscription, scope: [String: ScopeValue], expiry: UInt64) throws
}

final class NotifyStorage: NotifyStoring {

    private var publishers = Set<AnyCancellable>()

    private let messagesStore: KeyedDatabase<NotifyMessageRecord>
    private let database: NotifyDatabase

    private let newSubscriptionSubject = PassthroughSubject<NotifySubscription, Never>()
    private let updateSubscriptionSubject = PassthroughSubject<NotifySubscription, Never>()
    private let deleteSubscriptionSubject = PassthroughSubject<String, Never>()
    private let subscriptionsSubject = PassthroughSubject<[NotifySubscription], Never>()
    private let messagesSubject = PassthroughSubject<[NotifyMessageRecord], Never>()

    private let accountProvider: NotifyAccountProvider

    var newSubscriptionPublisher: AnyPublisher<NotifySubscription, Never> {
        return newSubscriptionSubject.eraseToAnyPublisher()
    }

    var updateSubscriptionPublisher: AnyPublisher<NotifySubscription, Never> {
        return updateSubscriptionSubject.eraseToAnyPublisher()
    }

    var deleteSubscriptionPublisher: AnyPublisher<String, Never> {
        return deleteSubscriptionSubject.eraseToAnyPublisher()
    }

    var subscriptionsPublisher: AnyPublisher<[NotifySubscription], Never> {
        return subscriptionsSubject.eraseToAnyPublisher()
    }

    init(database: NotifyDatabase, subscriptionStore: KeyedDatabase<NotifySubscription>, messagesStore: KeyedDatabase<NotifyMessageRecord>, accountProvider: NotifyAccountProvider) {
        self.database = database
        self.messagesStore = messagesStore
        self.accountProvider = accountProvider

        setupSubscriptions()
    }

    // MARK: Subscriptions

    func getAllSubscriptions() -> [NotifySubscription] {
        return (try? database.getAllSubscriptions()) ?? []
    }

    func getSubscriptions(account: Account) throws -> [NotifySubscription] {
        return try database.getSubscriptions(account: account)
    }

    func getSubscription(topic: String) throws -> NotifySubscription? {
        return try database.getSubscription(topic: topic)
    }

    func setSubscription(_ subscription: NotifySubscription) throws {
        try database.save(subscription: subscription)
        newSubscriptionSubject.send(subscription)
    }

    func replaceAllSubscriptions(_ subscriptions: [NotifySubscription]) throws {
        try database.save(subscriptions: subscriptions)
    }

    func deleteSubscription(topic: String) throws {
        try database.deleteSubscription(topic: topic)
        deleteSubscriptionSubject.send(topic)
    }

    func clearDatabase(account: Account) throws {
        for subscription in try getSubscriptions(account: account) {
            deleteMessages(topic: subscription.topic)
        }
        try database.deleteSubscription(account: account)
    }

    func updateSubscription(_ subscription: NotifySubscription, scope: [String: ScopeValue], expiry: UInt64) throws {
        let expiry = Date(timeIntervalSince1970: TimeInterval(expiry))
        let updated = NotifySubscription(subscription: subscription, scope: scope, expiry: expiry)
        try database.save(subscription: updated)
        updateSubscriptionSubject.send(updated)
    }

    // MARK: Messages

    func messagesPublisher(topic: String) -> AnyPublisher<[NotifyMessageRecord], Never> {
        return messagesSubject
            .map { $0.filter { $0.topic == topic } }
            .eraseToAnyPublisher()
    }

    func getMessages(topic: String) -> [NotifyMessageRecord] {
        return messagesStore.getAll(for: topic)
            .sorted{$0.publishedAt > $1.publishedAt}
    }

    func deleteMessages(topic: String) {
        messagesStore.deleteAll(for: topic)
    }

    func deleteMessage(id: String) {
        guard let result = messagesStore.find(id: id) else { return }
        messagesStore.delete(id: id, for: result.key)
    }

    func setMessage(_ record: NotifyMessageRecord) {
        messagesStore.set(element: record, for: record.topic)
    }
}

private extension NotifyStorage {

    enum Errors: Error {
        case subscriptionNotFound
    }

    func setupSubscriptions() {
        messagesStore.onUpdate = { [unowned self] in
            messagesSubject.send(messagesStore.getAll())
        }

        database.onSubscriptionsUpdate = { [unowned self] in
            let account = try accountProvider.getCurrentAccount()
            subscriptionsSubject.send(try getSubscriptions(account: account))
        }
    }
}
