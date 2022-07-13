import Foundation
import WalletConnectUtils

public struct Message: Codable, Equatable {
    internal init(topic: String? = nil, message: String, authorAccount: Account, timestamp: Int64) {
        self.topic = topic
        self.message = message
        self.authorAccount = authorAccount
        self.timestamp = timestamp
    }

    public var topic: String?
    public let message: String
    public let authorAccount: Account
    public let timestamp: Int64

    enum CodingKeys: String, CodingKey {
        case topic
        case message
        case authorAccount
        case timestamp
    }
}
