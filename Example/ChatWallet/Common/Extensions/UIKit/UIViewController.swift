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
        UIApplication.currentWindow.rootViewController = self
    }

    func push(from viewController: UIViewController) {
        viewController.navigationController?.pushViewController(self, animated: true)
    }

    func present(from viewController: UIViewController) {
        viewController.present(self, animated: true, completion: nil)
    }
    
    func presentFullScreen(from viewController: UIViewController, transparentBackground: Bool = false) {
        if transparentBackground {
            view.backgroundColor = .clear
        }
        modalPresentationStyle = .overCurrentContext
        viewController.present(self, animated: true, completion: nil)
    }

    func pop() {
        _ = navigationController?.popViewController(animated: true)
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

extension UIApplication {
    static var currentWindow: UIWindow {
        return UIApplication.shared.connectedScenes
            .compactMap { $0.delegate as? SceneDelegate }
            .first!.window!
    }
}
