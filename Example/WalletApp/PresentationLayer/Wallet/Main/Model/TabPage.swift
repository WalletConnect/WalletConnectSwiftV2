import UIKit

enum TabPage: CaseIterable {
    case wallet
//    case notifications
    case web3Inbox

    var title: String {
        switch self {
        case .wallet:
            return "Apps"
//        case .notifications:
//            return "Notifications"
        case .web3Inbox:
            return "w3i"
        }
    }

    var icon: UIImage {
        switch self {
        case .wallet:
            return UIImage(systemName: "house.fill")!
//        case .notifications:
//            return UIImage(systemName: "bell.fill")!
        case .web3Inbox:
            return UIImage(systemName: "bell.fill")!
        }
    }

    static var selectedIndex: Int {
        return 0
    }

    static var enabledTabs: [TabPage] {
        return [.wallet, .web3Inbox]
    }
}
