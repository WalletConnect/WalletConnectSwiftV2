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

        var v = bytes[bytes.count-1]
        if v >= 27 && v <= 30 {
            v -= 27
        } else if v >= 31 && v <= 34 {
            v -= 31
        } else if v >= 35 && v <= 38 {
            v -= 35
        }

        self.v = v
        self.r = [UInt8](bytes[0..<32])
        self.s = [UInt8](bytes[32..<64])
    }

    public var serialized: Data {
        return Data(r + s + [UInt8(v + 27)])
    }

    public func hex() -> String {
        return "0x" + serialized.toHexString()
    }
}
