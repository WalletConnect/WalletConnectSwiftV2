import Foundation

struct ValidSignatureMethod {
    static let methodHash = "0x1626ba7e"
    static let paddingIndex = "0000000000000000000000000000000000000000000000000000000000000040"
    static let signatureLength = "0000000000000000000000000000000000000000000000000000000000000041"
    static let signaturePadding = "00000000000000000000000000000000000000000000000000000000000000"

    let signature: Data
    let messageHash: Data

    func encode() -> String {
        return [
            ValidSignatureMethod.methodHash,
            leadingZeros(for: messageHash.toHexString(), end: false),
            ValidSignatureMethod.paddingIndex,
            ValidSignatureMethod.signatureLength,
            leadingZeros(for: signature.toHexString(), end: true),
            ValidSignatureMethod.signaturePadding
        ].joined()
    }

    private func leadingZeros(for value: String, end: Bool) -> String {
        let count = max(0, value.count % 32 - 2)
        let padding = String(repeating: "0", count: count)
        return end ? padding + value : value + padding
    }
}
