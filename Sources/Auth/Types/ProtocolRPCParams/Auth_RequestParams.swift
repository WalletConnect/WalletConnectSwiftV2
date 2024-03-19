import Foundation

/// wc_authRequest RPC method request param
struct Auth_RequestParams: Codable, Equatable {
    let requester: Requester
    let payloadParams: AuthPayloadStruct
}

extension Auth_RequestParams {
    struct Requester: Codable, Equatable {
        let publicKey: String
        let metadata: AppMetadata
    }
}
