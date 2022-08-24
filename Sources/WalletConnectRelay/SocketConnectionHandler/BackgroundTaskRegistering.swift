import Foundation
#if os(iOS)
import UIKit
#endif

protocol BackgroundTaskRegistering {
    func register(name: String, completion: @escaping () -> Void)
}

class BackgroundTaskRegistrar: BackgroundTaskRegistering {
#if os(iOS)
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
#endif

    func register(name: String, completion: @escaping () -> Void) {
#if os(iOS)
        invalidateIfNeeded()
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: name) { [unowned self] in
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
            completion()
        }
#endif
    }

    private func invalidateIfNeeded() {
#if os(iOS)
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
#endif
    }
}
