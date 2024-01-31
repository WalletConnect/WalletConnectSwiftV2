import SwiftUI

import Web3Wallet

final class SessionRequestModule {
    static let restorationIdentifier = "SessionRequestViewController"
    @discardableResult
    static func create(app: Application, sessionRequest: Request, importAccount: ImportAccount, sessionContext: VerifyContext?) -> UIViewController {
        let router = SessionRequestRouter(app: app)
        let interactor = SessionRequestInteractor()
        let presenter = SessionRequestPresenter(interactor: interactor, router: router, sessionRequest: sessionRequest, importAccount: importAccount, context: sessionContext)
        let view = SessionRequestView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)
        viewController.restorationIdentifier = Self.restorationIdentifier

        router.viewController = viewController

        return viewController
    }
}
