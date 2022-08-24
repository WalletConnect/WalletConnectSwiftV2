import Foundation
import WalletConnectUtils

/// wc_authRequest RPC method request param
struct AuthRequestParams: Codable, Equatable {
    let requester: Requester
    let payloadParams: AuthPayload

    static var tag: Int {
        return 3000
    }
}

extension AuthRequestParams {
    struct Requester: Codable, Equatable {
        let publicKey: String
        let metadata: AppMetadata
    }
}
