
import Foundation
import UIKit

protocol AppStateObserving {
    var onWillEnterForeground: (()->())? {get set}
    var onWillEnterBackground: (()->())? {get set}
}

class AppStateObserver: AppStateObserving {
    @objc var onWillEnterForeground: (() -> ())?
    
    @objc var onWillEnterBackground: (() -> ())?
    
    init() {
        subscribeNotificationCenter()
    }
    
    private func subscribeNotificationCenter() {
#if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(getter: onWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(getter: onWillEnterBackground),
            name: UIApplication.willResignActiveNotification,
            object: nil)
#endif
    }
}
