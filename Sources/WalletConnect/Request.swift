import Foundation
import WalletConnectUtils

public struct Request: Codable, Equatable {
    public internal(set) var id: Int64?
    public let topic: String
    public let method: String
    public let params: AnyCodable
    public let chainId: String?
}
