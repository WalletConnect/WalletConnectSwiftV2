import UIKit

final class ImportRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func presentChat(importAccount: ImportAccount) {
        MainModule.create(app: app, importAccount: importAccount).present()
    }
}
