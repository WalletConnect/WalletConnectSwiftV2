import Foundation

/// wc_sessionAuthenticate RPC method respond param
struct SessionAuthenticateResponseParams: Codable, Equatable {
    let responder: Participant
    let caip222Response: [Cacao]
}
