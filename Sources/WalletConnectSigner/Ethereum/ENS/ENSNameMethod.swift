import Foundation

struct ENSNameMethod {
    static let methodHash = "0x691f3431"

    let namehash: Data

    func encode() -> String {
        return [ENSNameMethod.methodHash, ContractEncoder.bytes(namehash)].joined()
    }
}
