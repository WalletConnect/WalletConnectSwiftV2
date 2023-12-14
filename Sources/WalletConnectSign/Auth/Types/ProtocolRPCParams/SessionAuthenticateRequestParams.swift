import Foundation

/// wc_sessionAuthenticate RPC method request param
struct SessionAuthenticateRequestParams: Codable, Equatable {
    let requester: Participant
    /// CAIP222 request
    let authPayload: AuthPayload
}


