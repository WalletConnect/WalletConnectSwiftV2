import SwiftUI

import WalletConnectSign

final class NewPairingModule {
    @discardableResult
    static func create(app: Application, walletConnectUri: WalletConnectURI) -> UIViewController {
        let router = NewPairingRouter(app: app)
        let interactor = NewPairingInteractor()
        let presenter = NewPairingPresenter(interactor: interactor, router: router, walletConnectUri: walletConnectUri)
        let view = NewPairingView().environmentObject(presenter)
        let viewController = UIHostingController(rootView: view)

        router.viewController = viewController

        return viewController
    }
}
