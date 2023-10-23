import UIKit

final class SettingsRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }

    @MainActor func presentWelcome() async {
        WelcomeModule.create(app: app).present()
    }
}
