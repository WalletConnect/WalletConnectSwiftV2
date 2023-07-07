import Foundation
@testable import WalletConnectRelay
@testable import WalletConnectNetworking
@testable import HTTPClient

extension NSError {

    static func mock(code: Int = -9999) -> NSError {
        NSError(domain: "com.walletconnect.sdk.tests.error", code: code, userInfo: nil)
    }
}

extension Error {

    var asNetworkError: NetworkError? {
        return self as? NetworkError
    }

    var asHttpError: HTTPError? {
        return self as? HTTPError
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

extension HTTPError {

    var isNoResponseError: Bool {
        if case .noResponse = self { return true }
        return false
    }

    var isBadStatusCodeError: Bool {
        if case .badStatusCode = self { return true }
        return false
    }

    var isNilDataError: Bool {
        if case .responseDataNil = self { return true }
        return false
    }

    var isDecodeError: Bool {
        if case .jsonDecodeFailed = self { return true }
        return false
    }
}

extension String: Error {}
