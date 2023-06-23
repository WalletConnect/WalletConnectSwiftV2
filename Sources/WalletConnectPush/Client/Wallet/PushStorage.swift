import Foundation
import Combine

final class PushStorage {

    private var publishers = Set<AnyCancellable>()

    private let subscriptionStore: SyncStore<PushSubscription>

    private let newSubscriptionSubject = PassthroughSubject<PushSubscription, Never>()
    private let deleteSubscriptionSubject = PassthroughSubject<String, Never>()

    var newSubscriptionPublisher: AnyPublisher<PushSubscription, Never> {
        return newSubscriptionSubject.eraseToAnyPublisher()
    }

    var deleteSubscriptionPublisher: AnyPublisher<String, Never> {
        return deleteSubscriptionSubject.eraseToAnyPublisher()
    }

    var subscriptionsPublisher: AnyPublisher<[PushSubscription], Never> {
        return subscriptionStore.dataUpdatePublisher
    }

    init(subscriptionStore: SyncStore<PushSubscription>) {
        self.subscriptionStore = subscriptionStore
        setupSubscriptions()
    }

    func initialize(account: Account) async throws {
        try await subscriptionStore.initialize(for: account)
    }

    func setupSubscriptions(account: Account) async throws {
        try subscriptionStore.setupSubscriptions(account: account)
    }

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
}

private extension PushStorage {

    func setupSubscriptions() {
        subscriptionStore.syncUpdatePublisher.sink { [unowned self] (_, _, update) in
            switch update {
            case .set(let subscription):
                newSubscriptionSubject.send(subscription)
            case .delete(let id):
                deleteSubscriptionSubject.send(id)
            }
        }.store(in: &publishers)
    }
}
