import Foundation
import JSONRPC
import WalletConnectNetworking
@testable import Auth

extension AuthRequestParams {
    static func stub(id: RPCID) -> AuthRequestParams {
        let appMetadata = AppMetadata(name: "", description: "", url: "", icons: [])
        let requester = AuthRequestParams.Requester(publicKey: "", metadata: appMetadata)
        let issueAt = ISO8601DateFormatter().string(from: Date())
        let payload = AuthPayload(requestParams: RequestParams.stub(), iat: issueAt)
        return AuthRequestParams(requester: requester, payloadParams: payload)
    }
}
