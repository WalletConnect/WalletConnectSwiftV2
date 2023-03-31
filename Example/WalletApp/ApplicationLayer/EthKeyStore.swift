import Web3

class EthKeyStore {
    static let shared = EthKeyStore()
    let privateKey: EthereumPrivateKey

    var address: EthereumAddress {
        return privateKey.address
    }

    private init() {
        privateKey = try! EthereumPrivateKey()
    }
}
