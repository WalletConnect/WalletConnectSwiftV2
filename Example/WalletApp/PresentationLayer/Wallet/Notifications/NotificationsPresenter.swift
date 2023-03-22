import UIKit
import Combine

final class NotificationsPresenter: ObservableObject {

    private let interactor: NotificationsInteractor
    private let router: NotificationsRouter
    private var disposeBag = Set<AnyCancellable>()

    @Published var subscriptions: [SubscriptionsViewModel] = []

    init(interactor: NotificationsInteractor, router: NotificationsRouter) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        
    }

    func didPress(_ subscription: SubscriptionsViewModel) {
        router.presentNotifications(subscription: subscription.subscription)
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
        return "Notifications"
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .always
    }
}

// MARK: Privates

private extension NotificationsPresenter {

    func setupSubscriptions() {
        self.subscriptions = interactor.getSubscriptions()
            .map {
                return SubscriptionsViewModel(subscription: $0)
            }
        interactor.subscriptionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pushSubscriptions in
                self?.subscriptions = pushSubscriptions
                    .map { SubscriptionsViewModel(subscription: $0) }
            }
            .store(in: &disposeBag)
    }

}
