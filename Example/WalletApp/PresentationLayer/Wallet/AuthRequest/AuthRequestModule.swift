import SwiftUI

import Web3Wallet

final class AuthRequestModule {
    @discardableResult
    static func create(app: Application, request: AuthRequest, importAccount: ImportAccount, context: VerifyContext?) -> UIViewController {
        let router = AuthRequestRouter(app: app)
        let interactor = AuthRequestInteractor(messageSigner: app.messageSigner)
        let presenter = AuthRequestPresenter(importAccount: importAccount, interactor: interactor, router: router, request: request, context: context)
        let view = AuthRequestView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }
}
