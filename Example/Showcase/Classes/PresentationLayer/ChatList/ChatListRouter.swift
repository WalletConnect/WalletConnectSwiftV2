import UIKit
import Chat

final class ChatListRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func presentInvite() {
        InviteModule.create(app: app)
            .wrapToNavigationController()
            .present(from: viewController)
    }

    func presentInviteList() {
        InviteListModule.create(app: app).push(from: viewController)
    }

    func presentChat(thread: Chat.Thread) {
        ChatModule.create(thread: thread, app: app).push(from: viewController)
    }
}
