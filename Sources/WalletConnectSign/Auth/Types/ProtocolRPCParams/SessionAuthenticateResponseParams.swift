import Foundation

/// wc_sessionAuthenticate RPC method respond param
struct SessionAuthenticateResponseParams: Codable, Equatable {
    let responder: Participant
    ///CAIP222 response
    let cacaos: [Cacao]
}
