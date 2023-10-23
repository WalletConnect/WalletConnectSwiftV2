import UIKit

enum TabPage: CaseIterable {
    case wallet
    case notifications
    case browser
    case settings

    var title: String {
        switch self {
        case .wallet:
            return "Apps"
        case .notifications:
            return "Notifications"
        case .settings:
            return "Settings"
        case .browser:
            return "Browser"
        }
    }

    var icon: UIImage {
        switch self {
        case .wallet:
            return UIImage(systemName: "house.fill")!
        case .notifications:
            return UIImage(systemName: "bell.fill")!
        case .browser:
            return UIImage(systemName: "network")!
        case .settings:
            return UIImage(systemName: "gearshape.fill")!
        }
    }

    static var selectedIndex: Int {
        return 0
    }

    static var enabledTabs: [TabPage] {
        return [.wallet, .notifications, .browser, .settings]
    }
}
