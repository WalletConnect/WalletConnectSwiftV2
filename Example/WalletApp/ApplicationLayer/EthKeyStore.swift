import Web3
import Foundation

class EthKeyStore {
    private let defaultsKey = "eth_prv_key"
    static let shared = EthKeyStore()
    let privateKey: EthereumPrivateKey

    var address: String {
        return privateKey.address.hex(eip55: true)
    }

    var privateKeyRaw: Data {
        return Data(privateKey.rawPrivateKey)
    }

    private init() {
        //        TODO: For testing !!!
        self.privateKey = try! EthereumPrivateKey(hexPrivateKey: "0x660bc2a94efbef506a499aef10066a914e2aaa1791362fd6d15a5b23a1078b44")

        //    if let privateKeyRaw = UserDefaults.standard.data(forKey: defaultsKey) {
        //            self.privateKey = try! EthereumPrivateKey(privateKeyRaw)
        //        } else {
        //            self.privateKey = try! EthereumPrivateKey()
        //            UserDefaults.standard.set(privateKeyRaw, forKey: defaultsKey)
        //        }
    }
}
