
import Foundation

public struct EthSendTransaction: Codable {
    public let from: String
    public let data: String
    public let gasLimit: String
    public let value: String
    public let to: String
    public let gasPrice: String
    public let nonce: String
}
