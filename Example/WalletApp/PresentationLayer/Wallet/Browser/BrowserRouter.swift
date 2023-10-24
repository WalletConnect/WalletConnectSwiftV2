import UIKit

final class BrowserRouter {
    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func presentWelcome() {
        BrowserModule.create(app: app).present()
    }
}
