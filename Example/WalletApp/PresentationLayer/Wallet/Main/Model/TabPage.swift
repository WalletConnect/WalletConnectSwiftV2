import UIKit

enum TabPage: CaseIterable {
    case wallet
    case web3Inbox
    case settings

    var title: String {
        switch self {
        case .wallet:
            return "Apps"
        case .web3Inbox:
            return "Web3Inbox"
        case .settings:
            return "Settings"
        }
    }

    var icon: UIImage {
        switch self {
        case .wallet:
            return UIImage(systemName: "house.fill")!
        case .web3Inbox:
            return UIImage(systemName: "bell.fill")!
        case .settings:
            return UIImage(systemName: "gearshape.fill")!
        }
    }

    static var selectedIndex: Int {
        return 0
    }

    static var enabledTabs: [TabPage] {
        return [.wallet, .web3Inbox, .settings]
    }
}
