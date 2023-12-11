import Foundation
import JSONRPC
import WalletConnectNetworking
@testable import Auth

extension AuthRequestParams {
    static func stub(id: RPCID, iat: String) -> AuthRequestParams {
        let appMetadata = AppMetadata(name: "", description: "", url: "", icons: [], redirect: AppMetadata.Redirect(native: "", universal: nil))
        let requester = AuthRequestParams.Requester(publicKey: "", metadata: appMetadata)
        let payload = AuthPayload(requestParams: RequestParams.stub(), iat: iat)
        return AuthRequestParams(requester: requester, payloadParams: payload)
    }
}
