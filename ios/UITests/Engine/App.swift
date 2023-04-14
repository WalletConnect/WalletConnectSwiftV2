import Foundation
import XCTest

enum App {
    case dapp
    case wallet
    case safari
    case springboard

    var bundleID: String {
        switch self {
        case .dapp:
            return "com.walletconnect.dapp"
        case .wallet:
            return "com.walletconnect.example"
        case .safari:
            return "com.apple.mobilesafari"
        case .springboard:
            return "com.apple.springboard"
        }
    }

    var displayName: String {
        switch self {
        case .dapp:
            return "dApp"
        case .wallet:
            return "WalletConnect Wallet"
        case .safari:
            return "Safari"
        case .springboard:
            fatalError()
        }
    }

    var instance: XCUIApplication {
        return XCUIApplication(bundleIdentifier: bundleID)
    }
}
