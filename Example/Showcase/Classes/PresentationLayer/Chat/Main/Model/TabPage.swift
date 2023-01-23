import UIKit

enum TabPage: CaseIterable {
    case chat
    case web3Inbox

    var title: String {
        switch self {
        case .chat:
            return "Chat"
        case .web3Inbox:
            return "Web3Inbox"
        }
    }

    var icon: UIImage {
        switch self {
        case .chat:
            return UIImage(systemName: "message.fill")!
        case .web3Inbox:
            return UIImage(systemName: "safari.fill")!
        }
    }

    static var selectedIndex: Int {
        return 0
    }

    static var enabledTabs: [TabPage] {
        return [.chat, .web3Inbox]
    }
}
