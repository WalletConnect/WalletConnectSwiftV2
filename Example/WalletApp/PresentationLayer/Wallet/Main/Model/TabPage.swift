import UIKit

enum TabPage: CaseIterable {
    case wallet
    case notifications
    case settings

    var title: String {
        switch self {
        case .wallet:
            return "Connections"
        case .notifications:
            return "Inbox"
        case .settings:
            return "Settings"
        }
    }

    var icon: UIImage {
        switch self {
        case .wallet:
            return UIImage(named: "connections_tab")!
        case .notifications:
            return UIImage(named: "inbox_tab")!
        case .settings:
            return UIImage(named: "settings_tab")!
        }
    }

    static var selectedIndex: Int {
        return 0
    }

    static var enabledTabs: [TabPage] {
        return [.wallet, .notifications, .settings]
    }
}
