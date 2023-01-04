import UIKit

enum TabPage: CaseIterable {
    case chat
    case wallet
    case web3Inbox

    var title: String {
        switch self {
        case .chat:
            return "Chat"
        case .wallet:
            return "Wallet"
        case .web3Inbox:
            return "Web3Inbox"
        }
    }

    var icon: UIImage {
        switch self {
        case .chat:
            return UIImage(systemName: "message.fill")!
        case .wallet:
            return UIImage(systemName: "signature")!
        case .web3Inbox:
            return UIImage(systemName: "safari.fill")!
        }
    }

    static var selectedIndex: Int {
        return 0
    }

    static var enabledTabs: [TabPage] {
        return [.chat, .wallet]
    }
}
