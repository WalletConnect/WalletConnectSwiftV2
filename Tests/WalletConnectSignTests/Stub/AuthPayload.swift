import Foundation
@testable import WalletConnectSign

extension AuthPayload {
    static func stub(requestParams: AuthRequestParams = AuthRequestParams.stub()) -> AuthPayload {
        AuthPayload(requestParams: requestParams, iat: "2021-09-30T16:25:24Z")
    }
}

extension AuthPayload {
    static func stub(nonce: String) -> AuthPayload {
        let issueAt = ISO8601DateFormatter().string(from: Date())
        return AuthPayload(requestParams: AuthRequestParams.stub(nonce: nonce), iat: issueAt)
    }
}
