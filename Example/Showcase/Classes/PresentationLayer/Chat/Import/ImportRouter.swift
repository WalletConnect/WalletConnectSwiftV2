import UIKit
import WalletConnectModal
import WalletConnectPairing

final class ImportRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }
    
    func presentWalletConnectModal() {
        WalletConnectModal.present(from: viewController)
    }

    func presentChat(importAccount: ImportAccount) {
        MainModule.create(app: app, importAccount: importAccount).present()
    }
}
