import Foundation
@testable import Auth
import JSONRPC

extension RequestSubscriptionPayload {
    static func stub(id: RPCID) -> RequestSubscriptionPayload {
        let appMetadata = AppMetadata(name: "", description: "", url: "", icons: [])
        let requester = AuthRequestParams.Requester(publicKey: "", metadata: appMetadata)
        let issueAt = ISO8601DateFormatter().string(from: Date())
        let payload = AuthPayload(requestParams: RequestParams.stub(), iat: issueAt)
        let params = AuthRequestParams(requester: requester, payloadParams: payload)
        let request = RPCRequest(method: "wc_authRequest", params: params, rpcid: id)
        return RequestSubscriptionPayload(id: 123, request: request)
    }
}
