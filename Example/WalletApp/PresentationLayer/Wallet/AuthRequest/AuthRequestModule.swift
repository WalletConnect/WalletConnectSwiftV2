import SwiftUI

import Web3Wallet

final class AuthRequestModule {
    @discardableResult
    static func create(app: Application, request: AuthRequest, context: VerifyContext?) -> UIViewController {
        let router = AuthRequestRouter(app: app)
        let interactor = AuthRequestInteractor()
        let presenter = AuthRequestPresenter(interactor: interactor, router: router, request: request, context: context)
        let view = AuthRequestView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }
}
