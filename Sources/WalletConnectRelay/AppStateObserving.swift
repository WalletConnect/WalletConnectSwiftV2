import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum ApplicationState {
    case background, foreground
}

protocol AppStateObserving: AnyObject {
    var currentState: ApplicationState { get async }
    var onWillEnterForeground: (() -> Void)? {get set}
    var onWillEnterBackground: (() -> Void)? {get set}
}

class AppStateObserver: AppStateObserving {

    @objc var onWillEnterForeground: (() -> Void)?

    @objc var onWillEnterBackground: (() -> Void)?

    init() {
        subscribeNotificationCenter()
    }

    @MainActor
    var currentState: ApplicationState{
        get async {
#if canImport(UIKit)
            let isActive = UIApplication.shared.applicationState == .active
            return isActive ? .foreground : .background
#elseif canImport(AppKit)
            let isActive = NSApplication.shared.isActive
            return isActive ? .foreground : .background
#endif
        }
    }

    private func subscribeNotificationCenter() {
#if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterBackground),
            name: UIApplication.willResignActiveNotification,
            object: nil)
#endif
    }

    @objc
    private func appWillEnterBackground() {
        onWillEnterBackground?()
    }

    @objc
    private func appWillEnterForeground() {
        onWillEnterForeground?()
    }
}
