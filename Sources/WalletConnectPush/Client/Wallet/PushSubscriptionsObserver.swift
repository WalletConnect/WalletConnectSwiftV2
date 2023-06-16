import Combine
import Foundation

class PushSubscriptionsObserver {
    private var publishers = [AnyCancellable]()

    public var subscriptionsPublisher: AnyPublisher<[PushSubscription], Never> {
        subscriptionsPublisherSubject.eraseToAnyPublisher()
    }
    private let subscriptionsPublisherSubject = PassthroughSubject<[PushSubscription], Never>()

    private let store: SyncStore<PushSubscription>

    init(store: SyncStore<PushSubscription>) {
        self.store = store
        setUpSubscription()
    }

    func setUpSubscription() {
        store.storeUpdatePublisher.sink(receiveValue: { [unowned self] in
            let subscriptions = store.getAll()
            subscriptionsPublisherSubject.send(subscriptions)
        }).store(in: &publishers)
    }
}
