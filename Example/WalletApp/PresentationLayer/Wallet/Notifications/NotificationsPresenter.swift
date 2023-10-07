import UIKit
import Combine
import WalletConnectNotify

final class NotificationsPresenter: ObservableObject {

    private let interactor: NotificationsInteractor
    private let router: NotificationsRouter
    private var disposeBag = Set<AnyCancellable>()

    @Published private var subscriptions: [NotifySubscription] = []
    @Published private var listings: [Listing] = []

    var subscriptionViewModels: [SubscriptionsViewModel] {
        return subscriptions
            .map { SubscriptionsViewModel(subscription: $0) }
            .sorted { lhs, rhs in
                return interactor.messagesCount(subscription: lhs.subscription) > interactor.messagesCount(subscription: rhs.subscription)
            }
    }

    var listingViewModels: [ListingViewModel] {
        return listings
            .map { ListingViewModel(listing: $0) }
            .sorted { lhs, rhs in
                return subscription(forListing: lhs) != nil && subscription(forListing: rhs) == nil
            }
    }

    init(interactor: NotificationsInteractor, router: NotificationsRouter) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        
    }

    @MainActor
    func fetch() async throws {
        listings = try await interactor.getListings()
    }

    func subscription(forListing listing: ListingViewModel) -> SubscriptionsViewModel? {
        return subscriptionViewModels.first(where: { $0.domain == listing.appDomain })
    }

    func subscribe(listing: ListingViewModel) async throws {
        if let domain = listing.appDomain {
            try await interactor.subscribe(domain: domain)
        }
    }

    func unsubscribe(subscription: SubscriptionsViewModel) async throws {
        try await interactor.unsubscribe(topic: subscription.subscription.topic)
    }

    func didPress(subscription: SubscriptionsViewModel) {
        router.presentNotifications(subscription: subscription.subscription)
    }

    func didPress(listing: ListingViewModel) {
        
    }

    func setupInitialState() {
        setupSubscriptions()
    }

    func removeSubscribtion(at indexSet: IndexSet) async {
        if let index = indexSet.first {
            await interactor.removeSubscription(subscriptionViewModels[index].subscription)
        }
    }
}

// MARK: SceneViewModel

extension NotificationsPresenter: SceneViewModel {
    var sceneTitle: String? {
        return "Inbox"
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .always
    }
}

// MARK: Privates

private extension NotificationsPresenter {

    func setupSubscriptions() {
        self.subscriptions = interactor.getSubscriptions()

        interactor.subscriptionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notifySubscriptions in
                self?.subscriptions = notifySubscriptions
            }
            .store(in: &disposeBag)
    }

}
