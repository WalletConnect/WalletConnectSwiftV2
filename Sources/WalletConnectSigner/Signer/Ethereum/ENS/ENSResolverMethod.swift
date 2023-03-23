import Foundation

struct ENSResolverMethod {
    static let methodHash = "0x0178b8bf"

    let namehash: Data

    func encode() -> String {
        return [ENSResolverMethod.methodHash, ContractEncoder.bytes(namehash)].joined()
    }
}
