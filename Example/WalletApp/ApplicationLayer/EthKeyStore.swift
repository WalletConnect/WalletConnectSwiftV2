import Web3
import Foundation

class EthKeyStore {
    private let defaultsKey = "eth_prv_key"
    static let shared = EthKeyStore()
    let privateKey: EthereumPrivateKey

    var address: String {
        return privateKey.address.hex(eip55: false)
    }

    var privateKeyRaw: Data {
        return Data(privateKey.rawPrivateKey)
    }

    private init() {
        if let privateKeyRaw = UserDefaults.standard.data(forKey: defaultsKey) {
            self.privateKey = try! EthereumPrivateKey(privateKeyRaw)
        } else {
            self.privateKey = try! EthereumPrivateKey()
            UserDefaults.standard.set(privateKeyRaw, forKey: defaultsKey)
        }
    }
}
