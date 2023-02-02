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

        Task(priority: .userInitiated) {
            await setupSubscriptions()
        }
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
    @MainActor
    func setupSubscriptions() async {
        await loadSubscriptions()

//        for await _ in interactor.subscriptionsSubscription() {
//            await loadSubscriptions()
//        }
    }

    @MainActor
    func loadSubscriptions() async {
        self.subscriptions = interactor.getSubscriptions()
            .map { SubscriptionsViewModel(subscription: $0) }
    }
}
