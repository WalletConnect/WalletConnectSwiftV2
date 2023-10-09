import WalletConnectNotify
import Combine

final class NotificationsInteractor {

    var subscriptionsPublisher: AnyPublisher<[NotifySubscription], Never> {
        return Notify.instance.subscriptionsPublisher
    }

    private let importAccount: ImportAccount

    init(importAccount: ImportAccount) {
        self.importAccount = importAccount
    }

    func getSubscriptions() -> [NotifySubscription] {
        let subs = Notify.instance.getActiveSubscriptions()
        return subs
    }

    func getListings() async throws -> [Listing] {
        let service = ListingsNetworkService()
        return try await service.getListings()
    }

    func removeSubscription(_ subscription: NotifySubscription) async {
        do {
            try await Notify.instance.deleteSubscription(topic: subscription.topic)
        } catch {
            print(error)
        }
    }

    func subscribe(domain: String) async throws {
        try await Notify.instance.subscribe(appDomain: domain, account: importAccount.account)
    }

    func unsubscribe(topic: String) async throws {
        try await Notify.instance.deleteSubscription(topic: topic)
    }

    func messages(for subscription: NotifySubscription) -> [NotifyMessageRecord] {
        return Notify.instance.getMessageHistory(topic: subscription.topic)
    }
}
