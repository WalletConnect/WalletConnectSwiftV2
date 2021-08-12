// 

import Foundation
import CryptoSwift

fileprivate var hexPrefix = "0x"

extension String {
    public func stripHexPrefix() -> String {
        var hex = self
        if hex.hasPrefix(hexPrefix) {
            hex = String(hex.dropFirst(hexPrefix.count))
        }
        return hex
    }
    
    public func addHexPrefix() -> String {
        return hexPrefix.appending(self)
    }
    
    public func toHexString() -> String {
        guard let data = data(using: .utf8) else {
            return ""
        }
        return data.toHexString()
    }
}

extension Data {
    public func dataToHexString() -> String {
        return map { String(format: "%02x", $0) }.joined()
    }
    
    public static func fromHex(_ hex: String) -> Data? {
        let string = hex.lowercased().stripHexPrefix()
        let array = Array<UInt8>(hex: string)
        if (array.count == 0) {
            if (hex == "0x" || hex == "") {
                return Data()
            } else {
                return nil
            }
        }
        return Data(array)
    }

}
