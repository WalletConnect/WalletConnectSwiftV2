import Foundation
@testable import WalletConnect

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
    
    var isInvalidMethodError: Bool {
        guard case .invalidMethod = wcError else { return false }
        return true
    }
    
    var isUnauthorizedNonControllerCallError: Bool {
        guard case .unauthorizedNonControllerCall = wcError else { return false }
        return true
    }
}
