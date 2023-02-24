import UIKit

final class WelcomeRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func presentImport() {
        ImportModule.create(app: app)
            .wrapToNavigationController()
            .present()
    }

    func presentMain(importAccount: ImportAccount) {
        MainModule.create(app: app, importAccount: importAccount)
            .present()
    }
    
    func openWallet(uri: String) {
        UIApplication.shared.open(URL(string: "walletapp://wc?uri=\(uri)")!)
    }
}
