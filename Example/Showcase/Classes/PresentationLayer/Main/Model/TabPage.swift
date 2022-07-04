import UIKit

enum TabPage: CaseIterable {
    case tokens
    case transactions
    case connect
    case notifications
    case chat

    var title: String {
        switch self {
        case .tokens:
            return "Tokens"
        case .transactions:
            return "Transactions"
        case .connect:
            return "Connect & Sign"
        case .notifications:
            return "Notifications"
        case .chat:
            return "Chat"
        }
    }

    var icon: UIImage {
        switch self {
        case .tokens:
            return UIImage(systemName: "star.fill")!
        case .transactions:
            return UIImage(systemName: "list.bullet.rectangle.fill")!
        case .connect:
            return UIImage(systemName: "signature")!
        case .notifications:
            return UIImage(systemName: "note")!
        case .chat:
            return UIImage(systemName: "message.fill")!
        }
    }

    static var selectedIndex: Int {
        return 4
    }

    static var enabledTabs: [TabPage] {
        return [.chat]
    }
}

