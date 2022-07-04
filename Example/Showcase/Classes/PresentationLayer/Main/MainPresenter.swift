import UIKit
import Combine

final class MainPresenter {

    private let router: MainRouter

    var tabs: [TabPage] {
        return TabPage.allCases
    }

    var viewControllers: [UIViewController] {
        return [
            UIViewController(),
            UIViewController(),
            UIViewController(),
            UIViewController(),
            router.chatViewController
        ]
    }

    init(router: MainRouter) {
        self.router = router
    }
}
