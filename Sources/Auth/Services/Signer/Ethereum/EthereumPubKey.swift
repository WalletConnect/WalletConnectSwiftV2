import Foundation

public struct EthereumPubKey {
    public let data: [UInt8]

    public init(data: [UInt8]) {
        self.data = data
    }

    public func hex() -> String {
        return "0x" + data.toHexString()
    }
}
