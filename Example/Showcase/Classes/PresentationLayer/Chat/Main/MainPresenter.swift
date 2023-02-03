import UIKit
import Combine

final class MainPresenter {

    private let account: Account
    private let router: MainRouter

    var tabs: [TabPage] {
        return TabPage.allCases
    }

    var viewControllers: [UIViewController] {
        return [
            router.chatViewController(account: account),
            router.web3InboxViewController(account: account),
        ]
    }

    init(router: MainRouter, account: Account) {
        self.account = account
        self.router = router
    }
}
