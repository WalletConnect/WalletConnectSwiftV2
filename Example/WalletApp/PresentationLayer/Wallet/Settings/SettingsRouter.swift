import UIKit

final class SettingsRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func presentWelcome() {
        WelcomeModule.create(app: app).present()
    }
}
