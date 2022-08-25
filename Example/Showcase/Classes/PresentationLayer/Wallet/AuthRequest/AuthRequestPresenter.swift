import UIKit
import Combine
import Auth

final class AuthRequestPresenter: ObservableObject {

    private let request: AuthRequest
    private let interactor: AuthRequestInteractor
    private let router: AuthRequestRouter
    private var disposeBag = Set<AnyCancellable>()

    init(request: AuthRequest, interactor: AuthRequestInteractor, router: AuthRequestRouter) {
        defer { setupInitialState() }
        self.request = request
        self.interactor = interactor
        self.router = router
    }

    var message: String {
        return request.message
    }
}

// MARK: SceneViewModel

extension AuthRequestPresenter: SceneViewModel {

    var sceneTitle: String? {
        return "Auth Request"
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .always
    }
}

// MARK: Privates

private extension AuthRequestPresenter {

    func setupInitialState() {

    }
}
