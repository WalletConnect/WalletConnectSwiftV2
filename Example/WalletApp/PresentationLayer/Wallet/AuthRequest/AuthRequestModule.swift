import SwiftUI

import Web3Wallet

final class AuthRequestModule {
    @discardableResult
    static func create(app: Application, request: AuthenticationRequest, importAccount: ImportAccount, context: VerifyContext?) -> UIViewController {
        let router = AuthRequestRouter(app: app)
        let presenter = AuthRequestPresenter(importAccount: importAccount, router: router, request: request, context: context, messageSigner: app.messageSigner)
        let view = AuthRequestView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }
}
