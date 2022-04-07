import Foundation
@testable import WalletConnect

extension NSError {
    
    static func mock(code: Int = -9999) -> NSError {
        NSError(domain: "com.walletconnect.sdk.tests.error", code: code, userInfo: nil)
    }
}

extension Error {
    
    var wcError: WalletConnectError? {
        self as? WalletConnectError
    }
    
    var isNoSessionMatchingTopicError: Bool {
        guard case .noSessionMatchingTopic = wcError else { return false }
        return true
    }
    
    var isSessionNotAcknowledgedError: Bool {
        guard case .sessionNotAcknowledged = wcError else { return false }
        return true
    }
    
    var isInvalidMetodError: Bool {
        guard case .invalidMethod = wcError else { return false }
        return true
    }
    
    var isUnauthorizedNonControllerCallError: Bool {
        guard case .unauthorizedNonControllerCall = wcError else { return false }
        return true
    }
}
