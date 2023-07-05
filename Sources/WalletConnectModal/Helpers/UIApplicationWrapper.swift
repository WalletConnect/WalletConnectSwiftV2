import Foundation

struct UIApplicationWrapper {
    let openURL: (URL, ((Bool) -> Void)?) -> Void
    let canOpenURL: (URL) -> Bool
}

#if canImport(UIKit)
import UIKit

extension UIApplicationWrapper {
    static let live = Self(
        openURL: { url, completion in
            UIApplication.shared.open(url, completionHandler: completion)
        },
        canOpenURL: { url in
            UIApplication.shared.canOpenURL(url)
        }
    )
}

#elseif canImport(AppKit)

import AppKit

extension UIApplicationWrapper {
    static let live = Self(
        openURL: { url, completion in
            NSWorkspace.shared.open(url)
        },
        canOpenURL: { url in
            return true
        }
    )
}
#endif
