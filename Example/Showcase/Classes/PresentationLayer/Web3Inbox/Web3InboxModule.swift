import SwiftUI

final class Web3InboxModule {

    @discardableResult
    static func create(app: Application, account: Account) -> UIViewController {
        let router = Web3InboxRouter(app: app)
        let viewController = Web3InboxViewController(account: account)
        router.viewController = viewController
        return viewController
    }

}
