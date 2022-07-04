import UIKit
import SwiftUI
import StoreKit

extension UIViewController {

    var topController: UIViewController {
        var topController = self
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }

    func present() {
        currentWindow.rootViewController = self
    }
    
    func push(from viewController: UIViewController) {
        viewController.navigationController?.pushViewController(self, animated: true)
    }
    
    func present(from viewController: UIViewController) {
        viewController.present(self, animated: true, completion: nil)
    }
    
    func pop() {
        let _ = navigationController?.popViewController(animated: true)
    }
    
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    func popToRoot() {
        navigationController?.popToRootViewController(animated: true)
    }

    func wrapToNavigationController() -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: self)
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }
}

private extension UIViewController {
    
    var currentWindow: UIWindow {
        return UIApplication.shared.connectedScenes
            .compactMap { $0.delegate as? SceneDelegate }
            .first!.window!
    }
}
