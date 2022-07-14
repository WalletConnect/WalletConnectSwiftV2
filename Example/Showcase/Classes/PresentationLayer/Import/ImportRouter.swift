import UIKit

final class ImportRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func presentChat(account: Account) {
        ChatListModule.create(app: app, account: account).push(from: viewController)
    }
}
