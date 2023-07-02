import UIKit

struct UIApplicationWrapper {
    let openURL: (URL, ((Bool) -> Void)?) -> Void
    let canOpenURL: (URL) -> Bool
}

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
