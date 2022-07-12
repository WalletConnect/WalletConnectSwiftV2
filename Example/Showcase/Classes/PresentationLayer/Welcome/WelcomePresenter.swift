import UIKit
import Combine

final class WelcomePresenter: ObservableObject {

    private let router: WelcomeRouter

    init(router: WelcomeRouter) {
        self.router = router
    }

    func didPressImport() {
        router.presentImport()
    }
}
