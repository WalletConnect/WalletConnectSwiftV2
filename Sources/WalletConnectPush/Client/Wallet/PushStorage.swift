import Foundation
import Combine

protocol PushStoring {
    func getSubscriptions() -> [PushSubscription]
    func getSubscription(topic: String) -> PushSubscription?
    func setSubscription(_ subscription: PushSubscription) async throws
    func deleteSubscription(topic: String) async throws
}

final class PushStorage: PushStoring {

    private var publishers = Set<AnyCancellable>()

    private let subscriptionStore: SyncStore<PushSubscription>
    private let messagesStore: KeyedDatabase<PushMessageRecord>

    private let newSubscriptionSubject = PassthroughSubject<PushSubscription, Never>()
    private let deleteSubscriptionSubject = PassthroughSubject<String, Never>()

    private let subscriptionStoreDelegate: PushSubscriptionStoreDelegate

    var newSubscriptionPublisher: AnyPublisher<PushSubscription, Never> {
        return newSubscriptionSubject.eraseToAnyPublisher()
    }

    var deleteSubscriptionPublisher: AnyPublisher<String, Never> {
        return deleteSubscriptionSubject.eraseToAnyPublisher()
    }

    var subscriptionsPublisher: AnyPublisher<[PushSubscription], Never> {
        return subscriptionStore.dataUpdatePublisher
    }

    init(
        subscriptionStore: SyncStore<PushSubscription>,
        messagesStore: KeyedDatabase<PushMessageRecord>,
        subscriptionStoreDelegate: PushSubscriptionStoreDelegate
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

    func getSubscriptions() -> [PushSubscription] {
        return subscriptionStore.getAll()
    }

    func getSubscription(topic: String) -> PushSubscription? {
        return subscriptionStore.get(for: topic)
    }

    func setSubscription(_ subscription: PushSubscription) async throws {
        try await subscriptionStore.set(object: subscription, for: subscription.account)
        newSubscriptionSubject.send(subscription)
    }

    func deleteSubscription(topic: String) async throws {
        try await subscriptionStore.delete(id: topic)
        deleteSubscriptionSubject.send(topic)
    }

    // MARK: Messages

    func getMessages(topic: String) -> [PushMessageRecord] {
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

    func setMessage(_ record: PushMessageRecord) {
        messagesStore.set(element: record, for: record.topic)
    }
}

private extension PushStorage {

    func setupSubscriptions() {
        subscriptionStore.syncUpdatePublisher.sink { [unowned self] (_, _, update) in
            switch update {
            case .set(let subscription):
                subscriptionStoreDelegate.onUpdate(subscription)
                newSubscriptionSubject.send(subscription)
            case .delete(let object):
                subscriptionStoreDelegate.onDelete(object, pushStorage: self)
                deleteSubscriptionSubject.send(object.topic)
            }
        }.store(in: &publishers)
    }
}
