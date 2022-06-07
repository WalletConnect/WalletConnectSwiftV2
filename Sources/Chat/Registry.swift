
import Foundation
import WalletConnectUtils

protocol Registry {
    func register(account: Account, pubKey: String) async throws 
    func resolve(account: Account) async throws -> String?
}

actor KeyValueRegistry: Registry  {
    
    var registryStore: [Account: String] = [:]
    
    func register(account address: Account, pubKey: String) async throws {
        registryStore[address] = pubKey
    }
    func resolve(account: Account) async throws -> String? {
        return registryStore[account]
    }
}
