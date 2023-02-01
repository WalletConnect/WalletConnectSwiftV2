import UIKit

enum TabPage: CaseIterable {
    case wallet
    case notifications

    var title: String {
        switch self {
        case .wallet:
            return "Apps"
        case .notifications:
            return "Notifications"
        }
    }

    var icon: UIImage {
        switch self {
        case .wallet:
            return UIImage(systemName: "message.fill")!
        case .notifications:
            return UIImage(systemName: "safari.fill")!
        }
    }

    static var selectedIndex: Int {
        return 0
    }

    static var enabledTabs: [TabPage] {
        return [.wallet, .notifications]
    }
}
