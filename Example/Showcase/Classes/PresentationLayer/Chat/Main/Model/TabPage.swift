import UIKit

enum TabPage: CaseIterable {
    case chat
    case wallet

    var title: String {
        switch self {
        case .chat:
            return "Chat"
        case .wallet:
            return "Wallet"
        }
    }

    var icon: UIImage {
        switch self {
        case .chat:
            return UIImage(systemName: "message.fill")!
        case .wallet:
            return UIImage(systemName: "signature")!
        }
    }

    static var selectedIndex: Int {
        return 0
    }

    static var enabledTabs: [TabPage] {
        return [.chat, .wallet]
    }
}
