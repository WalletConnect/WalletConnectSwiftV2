import UIKit
import Combine

final class MainPresenter {

    private let importAccount: ImportAccount
    private let router: MainRouter

    var tabs: [TabPage] {
        return TabPage.allCases
    }

    var viewControllers: [UIViewController] {
        return [
            router.chatViewController(account: importAccount.account),
            router.web3InboxViewController(importAccount: importAccount),
        ]
    }

    init(router: MainRouter, importAccount: ImportAccount) {
        self.importAccount = importAccount
        self.router = router
    }
}
