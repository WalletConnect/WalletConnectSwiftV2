import UIKit

final class ChatListRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func presentInvite() {
        InviteModule.create(app: app).push(from: viewController)
    }

    func presentInviteList() {
        InviteListModule.create(app: app).push(from: viewController)
    }

    func presentChat(topic: String) {
        ChatModule.create(topic: topic, app: app).push(from: viewController)
    }
}
