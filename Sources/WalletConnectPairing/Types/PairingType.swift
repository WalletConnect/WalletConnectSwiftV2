import Foundation

// Internal namespace for pairing payloads.
public enum PairingType {

    public struct DeleteParams: Codable, Equatable {
        let reason: Reason
    }

    public struct Reason: Codable, Equatable {
        let code: Int
        let message: String
    }

    public struct PingParams: Codable, Equatable {
        public init() { }
    }
}
