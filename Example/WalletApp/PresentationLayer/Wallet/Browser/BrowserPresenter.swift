import UIKit
import Combine
import WalletConnectNetworking

final class BrowserPresenter: ObservableObject {
    private let interactor: BrowserInteractor
    private let router: BrowserRouter
    
    private var disposeBag = Set<AnyCancellable>()

    init(interactor: BrowserInteractor, router: BrowserRouter) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
    }
}

// MARK: SceneViewModel
extension BrowserPresenter: SceneViewModel {
    var sceneTitle: String? {
        return "Browser"
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .always
    }
}

// MARK: Privates
private extension BrowserPresenter {
    func setupInitialState() {

    }
}
