import UIKit
import WalletConnectChat

final class ChatListRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func presentInvite(account: Account) {
        InviteModule.create(app: app, account: account)
            .wrapToNavigationController()
            .present(from: viewController)
    }

    func presentInviteList(account: Account) {
        InviteListModule.create(app: app, account: account).push(from: viewController)
    }

    func presentChat(thread: WalletConnectChat.Thread) {
        ChatModule.create(thread: thread, app: app).push(from: viewController)
    }

    func presentWelcome() {
        WelcomeModule.create(app: app).present()
    }
}
