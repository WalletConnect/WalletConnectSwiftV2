import Foundation
@testable import WalletConnect

extension NSError {
    
    static func mock(code: Int = -9999) -> NSError {
        NSError(domain: "com.walletconnect.sdk.tests.error", code: code, userInfo: nil)
    }
}
