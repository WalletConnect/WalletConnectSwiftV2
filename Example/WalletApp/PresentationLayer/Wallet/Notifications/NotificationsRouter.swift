import UIKit
import WalletConnectPush

final class NotificationsRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func presentNotifications(subscription: WalletConnectPush.PushSubscription) {

    }
}
