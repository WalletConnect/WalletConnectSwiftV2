import UIKit
import Combine

final class NotificationsPresenter: ObservableObject {

    private let interactor: NotificationsInteractor
    private let router: NotificationsRouter
    private var disposeBag = Set<AnyCancellable>()

    @Published var subscriptions: [SubscriptionsViewModel] = []
    @Published var listings: [ListingViewModel] = []

    init(interactor: NotificationsInteractor, router: NotificationsRouter) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        
    }

    @MainActor
    func fetch() async throws {
        self.listings = try await interactor.getListings().map { ListingViewModel(listing: $0) }
    }

    func subscription(forListing listing: ListingViewModel) -> SubscriptionsViewModel? {
        return subscriptions.first(where: { $0.domain == listing.appDomain })
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
            await interactor.removeSubscription(subscriptions[index].subscription)
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
        self.subscriptions = interactor.getSubscriptions().map { SubscriptionsViewModel(subscription: $0) }

        interactor.subscriptionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notifySubscriptions in
                self?.subscriptions = notifySubscriptions
                    .map { SubscriptionsViewModel(subscription: $0) }
            }
            .store(in: &disposeBag)
    }

}
