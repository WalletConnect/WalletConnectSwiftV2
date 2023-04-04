import Foundation

struct ContractEncoder {

    static func bytes(_ bytes: Data) -> String {
        let padding = 32 - bytes.count
        return bytes.toHexString() + String(repeating: "0", count: padding * 2)
    }

    static func leadingZeros(for value: String, end: Bool) -> String {
        let count = max(0, value.count % 32 - 2)
        let padding = String(repeating: "0", count: count)
        return end ? padding + value : value + padding
    }
}
