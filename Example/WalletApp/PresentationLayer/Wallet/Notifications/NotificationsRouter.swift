import UIKit
import WalletConnectNotify

final class NotificationsRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func presentNotifications(subscription: NotifySubscription) {
        SubscriptionModule.create(app: app, subscription: subscription)
            .push(from: viewController)
    }
}
