import UIKit

final class ChatRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }
}
