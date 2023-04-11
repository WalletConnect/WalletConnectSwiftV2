import Foundation
import XCTest

enum App {
    case dapp
    case wallet
    case springboard

    var instance: XCUIApplication {
        return XCUIApplication(bundleIdentifier: bundleID)
    }
    
    private var bundleID: String {
        switch self {
        case .dapp:
            return "com.walletconnect.dapp"
        case .wallet:
            return "com.walletconnect.walletapp"
        case .springboard:
            return "com.apple.springboard"
        }
    }
}
