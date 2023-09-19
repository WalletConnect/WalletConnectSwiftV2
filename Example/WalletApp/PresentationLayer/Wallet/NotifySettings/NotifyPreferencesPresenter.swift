import UIKit
import Combine
import WalletConnectNotify

final class NotifyPreferencesPresenter: ObservableObject {

    private let subscription: NotifySubscription
    private let interactor: NotifyPreferencesInteractor
    private let router: NotifyPreferencesRouter
    private var disposeBag = Set<AnyCancellable>()

    var subscriptionViewModel: SubscriptionsViewModel {
        return SubscriptionsViewModel(subscription: subscription)
    }

    init(subscription: NotifySubscription, interactor: NotifyPreferencesInteractor, router: NotifyPreferencesRouter) {
        defer { setupInitialState() }
        self.subscription = subscription
        self.interactor = interactor
        self.router = router
    }
}

// MARK: SceneViewModel

extension NotifyPreferencesPresenter: SceneViewModel {

}

// MARK: Privates

private extension NotifyPreferencesPresenter {

    func setupInitialState() {

    }
}
