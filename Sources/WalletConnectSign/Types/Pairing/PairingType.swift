import Foundation

// Internal namespace for pairing payloads.
internal enum PairingType {

    struct DeleteParams: Codable, Equatable {
        let reason: Reason
    }

    struct Reason: Codable, Equatable {
        let code: Int
        let message: String
    }

    struct PingParams: Codable, Equatable {}
}
