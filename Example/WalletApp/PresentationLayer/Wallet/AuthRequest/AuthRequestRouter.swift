import UIKit

final class AuthRequestRouter {
    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }
    
    func dismiss() {
        viewController.dismiss()
    }
}
