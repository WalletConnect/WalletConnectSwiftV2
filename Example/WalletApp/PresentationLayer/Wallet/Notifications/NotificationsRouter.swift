import UIKit
import WalletConnectNotify

final class NotificationsRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func presentNotifications(subscription: NotifySubscription) {
        let module = SubscriptionModule.create(app: app, subscription: subscription)
        module.hidesBottomBarWhenPushed = true
        module.push(from: viewController)
    }
}
