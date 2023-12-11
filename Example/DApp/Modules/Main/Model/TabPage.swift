import UIKit

enum TabPage: CaseIterable {
    case sign
    case auth

    var title: String {
        switch self {
        case .sign:
            return "Sign"
        case .auth:
            return "Auth"
        }
    }

    var icon: UIImage {
        switch self {
        case .sign:
            return UIImage(named: "pen")!
        case .auth:
            return UIImage(named: "auth")!
        }
    }

    static var selectedIndex: Int {
        return 0
    }

    static var enabledTabs: [TabPage] {
        return [.sign, .auth]
    }
}
