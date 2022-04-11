import Foundation
@testable import Relayer

extension Error {
    
    var asNetworkError: NetworkError? {
        return self as? NetworkError
    }
}

extension NetworkError {

    var isWebSocketError: Bool {
        guard case .webSocketNotConnected = self else { return false }
        return true
    }
    
    var isSendMessageError: Bool {
        guard case .sendMessageFailed = self else { return false }
        return true
    }
    
    var isReceiveMessageError: Bool {
        guard case .receiveMessageFailure = self else { return false }
        return true
    }
}

extension String: Error {}
