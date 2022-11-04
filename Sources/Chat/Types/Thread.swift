import Foundation

public struct Thread: Codable {
    public let topic: String
    public let selfAccount: Account
    public let peerAccount: Account
}
