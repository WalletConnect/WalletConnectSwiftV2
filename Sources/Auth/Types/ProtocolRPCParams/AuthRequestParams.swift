import Foundation
import WalletConnectUtils

/// wc_authRequest RPC method request param
struct AuthRequestParams: Codable, Equatable {
    let requester: Requester
    let payloadParams: AuthPayload
}

extension AuthRequestParams {
    struct Requester: Codable, Equatable {
        let publicKey: String
        let metadata: AppMetadata
    }
}
