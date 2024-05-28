
import Foundation
import UIKit
import WalletConnectSign

final class ConfigRouter {
    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }
}
