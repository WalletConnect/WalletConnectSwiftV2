import Foundation
import WalletConnectUtils

public struct Message: Codable, Equatable {
    public var topic: String
    public let message: String
    public let authorAccount: Account
    public let timestamp: Int64
}
