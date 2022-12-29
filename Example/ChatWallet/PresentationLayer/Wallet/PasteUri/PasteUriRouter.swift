import UIKit

final class PasteUriRouter {
    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }
}
