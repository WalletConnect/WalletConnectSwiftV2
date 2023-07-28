import Foundation
import Combine

protocol NotifyStoring {
    func getSubscriptions() -> [NotifySubscription]
    func getSubscription(topic: String) -> NotifySubscription?
    func setSubscription(_ subscription: NotifySubscription) async throws
    func deleteSubscription(topic: String) async throws
}

final class NotifyStorage: NotifyStoring {

    private var publishers = Set<AnyCancellable>()

    private let subscriptionStore: SyncStore<NotifySubscription>
    private let messagesStore: KeyedDatabase<NotifyMessageRecord>

    private let newSubscriptionSubject = PassthroughSubject<NotifySubscription, Never>()
    private let deleteSubscriptionSubject = PassthroughSubject<String, Never>()

    private let subscriptionStoreDelegate: NotifySubscriptionStoreDelegate

    var newSubscriptionPublisher: AnyPublisher<NotifySubscription, Never> {
        return newSubscriptionSubject.eraseToAnyPublisher()
    }

    var deleteSubscriptionPublisher: AnyPublisher<String, Never> {
        return deleteSubscriptionSubject.eraseToAnyPublisher()
    }

    var subscriptionsPublisher: AnyPublisher<[NotifySubscription], Never> {
        return subscriptionStore.dataUpdatePublisher
    }

    init(
        subscriptionStore: SyncStore<NotifySubscription>,
        messagesStore: KeyedDatabase<NotifyMessageRecord>,
        subscriptionStoreDelegate: NotifySubscriptionStoreDelegate
    ) {
        self.subscriptionStore = subscriptionStore
        self.messagesStore = messagesStore
        self.subscriptionStoreDelegate = subscriptionStoreDelegate
        setupSubscriptions()
    }

    // MARK: Configuration

    func initialize(account: Account) async throws {
        try await subscriptionStore.initialize(for: account)
    }

    func setupSubscriptions(account: Account) async throws {
        try subscriptionStore.setupSubscriptions(account: account)
    }

    // MARK: Subscriptions

    func getSubscriptions() -> [NotifySubscription] {
        return subscriptionStore.getAll()
    }

    func getSubscription(topic: String) -> NotifySubscription? {
        return subscriptionStore.get(for: topic)
    }

    func setSubscription(_ subscription: NotifySubscription) async throws {
        try await subscriptionStore.set(object: subscription, for: subscription.account)
        newSubscriptionSubject.send(subscription)
    }

    func deleteSubscription(topic: String) async throws {
        try await subscriptionStore.delete(id: topic)
        deleteSubscriptionSubject.send(topic)
    }

    // MARK: Messages

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

    func setupSubscriptions() {
        subscriptionStore.syncUpdatePublisher.sink { [unowned self] (_, _, update) in
            switch update {
            case .set(let subscription):
                subscriptionStoreDelegate.onUpdate(subscription)
                newSubscriptionSubject.send(subscription)
            case .delete(let object):
                subscriptionStoreDelegate.onDelete(object, notifyStorage: self)
                deleteSubscriptionSubject.send(object.topic)
            }
        }.store(in: &publishers)
    }
}
