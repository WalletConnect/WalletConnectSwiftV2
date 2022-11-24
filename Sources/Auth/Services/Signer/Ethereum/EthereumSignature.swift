import Foundation

public struct EthereumSignature {
    public let v: UInt8
    public let r: [UInt8]
    public let s: [UInt8]

    public init(v: UInt8, r: [UInt8], s: [UInt8]) {
        self.v = v
        self.r = r
        self.s = s
    }

    public init(serialized: Data) {
        v = UInt8(serialized.bytes[serialized.count-1])
        r = [UInt8](serialized.bytes[0..<32])
        s = [UInt8](serialized.bytes[32..<64])
    }

    public var serialized: Data {
        return Data(r + s + [UInt8(v)])
    }

    public func hex() -> String {
        return "0x" + serialized.toHexString()
    }
}
