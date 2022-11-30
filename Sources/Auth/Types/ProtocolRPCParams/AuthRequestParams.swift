import Foundation

/// wc_authRequest RPC method request param
public struct AuthRequestParams: Codable, Equatable {
    public let requester: Requester
    public let payloadParams: AuthPayload
}

extension AuthRequestParams {
    public struct Requester: Codable, Equatable {
        let publicKey: String
        let metadata: AppMetadata
    }
}
