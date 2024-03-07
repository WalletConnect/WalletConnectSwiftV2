import Foundation

/// wc_sessionAuthenticate RPC method request param
struct SessionAuthenticateRequestParams: Codable, Equatable, Expirable {
    let requester: Participant
    /// CAIP222 request
    let authPayload: AuthPayload
    let expiryTimestamp: UInt64

    init(requester: Participant, authPayload: AuthPayload, ttl: TimeInterval) {
        self.requester = requester
        self.authPayload = authPayload
        self.expiryTimestamp = UInt64(Date().timeIntervalSince1970) + UInt64(ttl)
    }

    func isExpired(currentDate: Date = Date()) -> Bool {
        let expiryDate = Date(timeIntervalSince1970: TimeInterval(expiryTimestamp))
        return expiryDate < currentDate
    }
}


