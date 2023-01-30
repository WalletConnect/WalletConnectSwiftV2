import UIKit

final class ImportRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func presentChat(account: Account) {
        MainModule.create(app: app, account: account).present()
    }
}
