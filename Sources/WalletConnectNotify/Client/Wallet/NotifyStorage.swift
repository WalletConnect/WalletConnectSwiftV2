import Foundation
import Combine

protocol NotifyStoring {
    func getAllSubscriptions() -> [NotifySubscription]
    func getSubscriptions(account: Account) -> [NotifySubscription]
    func getSubscription(topic: String) -> NotifySubscription?
    func setSubscription(_ subscription: NotifySubscription) throws
    func deleteSubscription(topic: String) throws
    func clearDatabase(account: Account) throws
}

final class NotifyStorage: NotifyStoring {

    private var publishers = Set<AnyCancellable>()

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

    var messagesPublisher: AnyPublisher<[NotifyMessageRecord], Never> {
        return messagesSubject.eraseToAnyPublisher()
    }

    init(database: NotifyDatabase, accountProvider: NotifyAccountProvider) {
        self.database = database
        self.accountProvider = accountProvider

        setupSubscriptions()
    }

    // MARK: Subscriptions

    func getAllSubscriptions() -> [NotifySubscription] {
        return database.getAllSubscriptions()
    }

    func getSubscriptions(account: Account) -> [NotifySubscription] {
        return database.getSubscriptions(account: account)
    }

    func getSubscription(topic: String) -> NotifySubscription? {
        return database.getSubscription(topic: topic)
    }

    func setSubscription(_ subscription: NotifySubscription) throws {
        try database.save(subscription: subscription)
        newSubscriptionSubject.send(subscription)
    }

    func replaceAllSubscriptions(_ subscriptions: [NotifySubscription]) throws {
        try database.replace(subscriptions: subscriptions)
    }

    func deleteSubscription(topic: String) throws {
        try database.deleteSubscription(topic: topic)
        deleteSubscriptionSubject.send(topic)
    }

    func clearDatabase(account: Account) throws {
        for subscription in getSubscriptions(account: account) {
            try database.deleteMessages(topic: subscription.topic)
        }
        try database.deleteSubscription(account: account)
    }

    func updateSubscription(_ subscription: NotifySubscription, scope: [String: ScopeValue], expiry: UInt64) throws {
        let expiry = Date(timeIntervalSince1970: TimeInterval(expiry))
        let updated = NotifySubscription(subscription: subscription, scope: scope, expiry: expiry)
        try database.save(subscription: updated)
        updateSubscriptionSubject.send(updated)
    }

    func subscriptionsPublisher(account: Account) -> AnyPublisher<[NotifySubscription], Never> {
        return subscriptionsSubject
            .map { $0.filter { $0.account == account } }
            .eraseToAnyPublisher()
    }

    // MARK: Messages

    func messagesPublisher(topic: String) -> AnyPublisher<[NotifyMessageRecord], Never> {
        return messagesSubject
            .map { $0.filter { $0.topic == topic } }
            .eraseToAnyPublisher()
    }

    func getMessages(topic: String) -> [NotifyMessageRecord] {
        return database.getMessages(topic: topic)
    }

    func deleteMessages(topic: String) throws {
        try database.deleteMessages(topic: topic)
    }

    func deleteMessage(id: String) throws {
        try database.deleteMessage(id: id)
    }

    func setMessage(_ message: NotifyMessageRecord) throws {
        try database.save(message: message)
    }

    func setMessages(_ messages: [NotifyMessageRecord]) throws {
        try database.save(messages: messages)
    }
}

private extension NotifyStorage {

    enum Errors: Error {
        case subscriptionNotFound
    }

    func setupSubscriptions() {
        database.onMessagesUpdate = { [unowned self] in
            messagesSubject.send(database.getAllMessages())
        }

        database.onSubscriptionsUpdate = { [unowned self] in
            let account = try accountProvider.getCurrentAccount()
            subscriptionsSubject.send(getSubscriptions(account: account))
        }
    }
}
