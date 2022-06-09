
import Foundation
import WalletConnectUtils

protocol Registry {
    func register(account: Account, pubKey: String)
    func resolve(account: Account) -> String?
}

class KeyValueRegistry: Registry  {
    
    var registryStore: [Account: String] = [:]
    
    func register(account address: Account, pubKey: String) {
        registryStore[address] = pubKey
    }
    
    func resolve(account: Account) -> String? {
        return registryStore[account]
    }
}
