import Foundation
import WalletConnectNotify
import Combine

final class NotificationsInteractor {

    var subscriptionsPublisher: AnyPublisher<[NotifySubscription], Never> {
        return Notify.instance.subscriptionsPublisher(account: importAccount.account)
    }

    private let importAccount: ImportAccount

    init(importAccount: ImportAccount) {
        self.importAccount = importAccount
    }

    func getSubscriptions() -> [NotifySubscription] {
        let subs = Notify.instance.getActiveSubscriptions(account: importAccount.account)
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
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = subscriptionsPublisher
                .sink { subscriptions in
                    guard subscriptions.contains(where: { $0.metadata.url == domain }) else { return }
                    cancellable?.cancel()
                    continuation.resume(with: .success(()))
                }
            
            Task { [cancellable] in
                do {
                    try await Notify.instance.subscribe(appDomain: domain, account: importAccount.account)
                } catch {
                    cancellable?.cancel()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func unsubscribe(topic: String) async throws {
        try await Notify.instance.deleteSubscription(topic: topic)
    }

    func messages(for subscription: NotifySubscription) -> [NotifyMessageRecord] {
        return Notify.instance.getMessageHistory(topic: subscription.topic)
    }
}

private extension NotificationsInteractor {

    enum Errors: Error, LocalizedError {
        case subscribeTimeout

        var errorDescription: String? {
            switch self {
            case .subscribeTimeout:
                return "Subscribe method timeout"
            }
        }
    }
}
