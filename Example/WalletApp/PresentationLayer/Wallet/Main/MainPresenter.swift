import UIKit
import Combine

final class MainPresenter {

    private let router: MainRouter

    var tabs: [TabPage] {
        return TabPage.allCases
    }

    var viewControllers: [UIViewController] {
        return [
            router.walletViewController(),
            router.notificationsViewController(),
        ]
    }

    init(router: MainRouter) {
        self.router = router
    }
}
