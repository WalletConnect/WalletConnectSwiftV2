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
        let bytes = [UInt8](serialized)
        v = UInt8(bytes[serialized.count-1])
        r = [UInt8](bytes[0..<32])
        s = [UInt8](bytes[32..<64])
    }

    public var serialized: Data {
        return Data(r + s + [UInt8(v)])
    }

    public func hex() -> String {
        return "0x" + serialized.toHexString()
    }
}
