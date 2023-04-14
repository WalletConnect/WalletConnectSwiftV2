import SwiftUI

final class Web3InboxModule {

    @discardableResult
    static func create(app: Application, importAccount: ImportAccount) -> UIViewController {
        let router = Web3InboxRouter(app: app)
        let viewController = Web3InboxViewController(importAccount: importAccount)
        router.viewController = viewController
        return viewController
    }

}
