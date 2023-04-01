import Foundation

extension Data {

    public var prefixed: Data {
        return "\u{19}Ethereum Signed Message:\n\(count)"
            .data(using: .utf8)! + self
    }
}
