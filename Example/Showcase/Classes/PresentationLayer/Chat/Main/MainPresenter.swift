import UIKit
import Combine

final class MainPresenter {

    private let router: MainRouter

    var tabs: [TabPage] {
        return TabPage.allCases
    }

    var viewControllers: [UIViewController] {
        return [
            router.chatViewController,
            router.web3InboxViewController,
        ]
    }

    init(router: MainRouter) {
        self.router = router
    }
}
