import UIKit
import Combine
import WalletConnectNotify

final class NotifyPreferencesPresenter: ObservableObject {

    private let subscription: NotifySubscription
    private let interactor: NotifyPreferencesInteractor
    private let router: NotifyPreferencesRouter
    private var disposeBag = Set<AnyCancellable>()

    var subscriptionViewModel: SubscriptionsViewModel {
        return SubscriptionsViewModel(subscription: subscription, messages: [])
    }

    var preferences: [String] {
        return subscriptionViewModel.scope.keys.sorted()
    }

    var isUpdateDisabled: Bool {
        return update == subscription.scope
    }

    @Published var update: SubscriptionScope = [:]

    init(subscription: NotifySubscription, interactor: NotifyPreferencesInteractor, router: NotifyPreferencesRouter) {
        defer { setupInitialState() }
        self.subscription = subscription
        self.interactor = interactor
        self.router = router
    }

    @MainActor
    func updateDidPress() async throws {
        let scope = update
            .filter { $0.value.enabled }
            .map { $0.key }

        try await interactor.updatePreferences(subscription: subscription, scope: Set(scope))

        router.dismiss()
    }
}

// MARK: SceneViewModel

extension NotifyPreferencesPresenter: SceneViewModel {

}

// MARK: Privates

private extension NotifyPreferencesPresenter {

    func setupInitialState() {
        update = subscription.scope
    }
}
