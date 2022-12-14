import Foundation

class SubscriptionsProvider {
    let store: CodableStore<PushSubscription>

    init(store: CodableStore<PushSubscription>) {
        self.store = store
    }

    public func getActiveSubscriptions() -> [PushSubscription] {
        store.getAll()
    }
}
