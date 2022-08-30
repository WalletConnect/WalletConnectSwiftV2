import Foundation
#if os(iOS)
import UIKit
#endif

protocol AppStateObserving {
    var onWillEnterForeground: (() -> Void)? {get set}
    var onWillEnterBackground: (() -> Void)? {get set}
}

class AppStateObserver: AppStateObserving {
    @objc var onWillEnterForeground: (() -> Void)?

    @objc var onWillEnterBackground: (() -> Void)?

    init() {
        subscribeNotificationCenter()
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
