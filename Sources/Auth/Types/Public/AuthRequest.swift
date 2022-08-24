import Foundation

public struct AuthRequest: Equatable, Codable {
    public let id: RPCID
    /// EIP-4361: Sign-In with Ethereum message
    public let message: String
}
