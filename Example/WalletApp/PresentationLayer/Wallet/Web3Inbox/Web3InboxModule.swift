import SwiftUI

final class Web3InboxModule {

    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = Web3InboxRouter(app: app)
        let viewController = Web3InboxViewController()
        router.viewController = viewController
        return viewController
    }

}
