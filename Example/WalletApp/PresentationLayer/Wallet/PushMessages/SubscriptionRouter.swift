import UIKit
import WalletConnectNotify

final class SubscriptionRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func dismiss() {
        viewController.pop()
    }

    func presentPreferences(subscription: NotifySubscription) {
        let controller = NotifyPreferencesModule.create(app: app, subscription: subscription)
        controller.sheetPresentationController?.detents = [.custom(resolver: { _ in UIScreen.main.bounds.height * 2/3 })]
        controller.sheetPresentationController?.prefersGrabberVisible = true
        controller.present(from: viewController)
    }
}
