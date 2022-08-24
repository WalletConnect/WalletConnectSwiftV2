@testable import Auth
import Foundation
import WalletConnectPairing

extension AuthRequestParams {
    static func stub(nonce: String = "32891756") -> AuthRequestParams {
        let payload = AuthPayload.stub(nonce: nonce)
        return AuthRequestParams(requester: Requester.stub(), payloadParams: payload)
    }
}

extension AuthRequestParams.Requester {
    static func stub() -> AuthRequestParams.Requester {
        AuthRequestParams.Requester(publicKey: "", metadata: AppMetadata.stub())
    }
}
