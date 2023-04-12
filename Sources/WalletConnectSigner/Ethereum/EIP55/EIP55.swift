import Foundation

// NOTE: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-55.md
public struct EIP55 {

    private let crypto: CryptoProvider

    public init(crypto: CryptoProvider) {
        self.crypto = crypto
    }

    public func encode(_ string: String) -> String {
        let data = Data(hex: string.replacingOccurrences(of: "0x", with: ""))
        return "0x" + encode(data)
    }

    public func encode(_ data: Data) -> String {
        let address = data.toHexString()

        let hash = crypto.keccak256(address.data(using: .ascii)!).toHexString()

        return zip(address, hash)
            .map { a, h -> String in
                switch (a, h) {
                case ("0", _), ("1", _), ("2", _), ("3", _), ("4", _), ("5", _), ("6", _), ("7", _), ("8", _), ("9", _):
                    return String(a)
                case (_, "8"), (_, "9"), (_, "a"), (_, "b"), (_, "c"), (_, "d"), (_, "e"), (_, "f"):
                    return String(a).uppercased()
                default:
                    return String(a).lowercased()
                }
            }
            .joined()
    }
}
