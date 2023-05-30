import UIKit

struct UIApplicationWrapper {
    let openURL: (URL) -> Void
    let canOpenURL: (URL) -> Bool
}

extension UIApplicationWrapper {
    static let live = Self(
        openURL: { url in
            Task { @MainActor in
                await UIApplication.shared.open(url)
            }
        },
        canOpenURL: { url in
            UIApplication.shared.canOpenURL(url)
        }
    )
}
