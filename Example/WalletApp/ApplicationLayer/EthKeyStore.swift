import Web3
import Foundation

class EthKeyStore {
    static let shared = EthKeyStore()
    let privateKey: EthereumPrivateKey

    var address: String {
        return privateKey.address.hex(eip55: false)
    }

    var privateKeyRaw: Data {
        return Data(privateKey.rawPrivateKey)
    }

    private init() {
        privateKey = try! EthereumPrivateKey()
    }
}
