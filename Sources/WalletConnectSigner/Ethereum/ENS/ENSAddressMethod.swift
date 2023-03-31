import Foundation

struct ENSAddressMethod {
    static let methodHash = "0x3b3b57de"

    let namehash: Data

    func encode() -> String {
        return [ENSAddressMethod.methodHash, ContractEncoder.bytes(namehash)].joined()
    }
}
