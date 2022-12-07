import Foundation

public extension UInt8 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt8>.size)
    }
}

public extension Array where Element == UInt8 {

    func toHexString() -> String {
        return Data(self).toHexString()
    }
}
