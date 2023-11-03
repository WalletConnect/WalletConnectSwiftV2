import Foundation

/// wc_authRequest RPC method request param
struct AuthRequestParams: Codable, Equatable {
    let requester: Requester
    let payloadParams: AuthenticationPayload
}

extension AuthRequestParams {
    struct Requester: Codable, Equatable {
        let publicKey: String
        let metadata: AppMetadata
    }
}
