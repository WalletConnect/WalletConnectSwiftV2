import Foundation
import WalletConnectRelay
import WalletConnectUtils

protocol Registry {
    func register(account: Account, pubKey: String) async throws
    func resolve(account: Account) async throws -> String
}

actor KeyserverRegistryProvider: Registry {

    var client: HTTPClient

     init(client: HTTPClient) {
         self.client = client
     }

    func register(account: Account, pubKey: String) async throws {
        let service = RegisterService(userAccount: UserAccount(account: account, publicKey: pubKey))
        try await client.request(service: service)
    }

    func resolve(account: Account) async throws -> String {
        let service = ResolveService(account: account)
        let resolvedAccount = try await client.request(UserAccount.self, at: service)
        return resolvedAccount.publicKey
    }
}

actor KeyValueRegistry: Registry {

    private var registryStore: [Account: String] = [:]

    func register(account address: Account, pubKey: String) async throws {
        registryStore[address] = pubKey
    }

    func resolve(account: Account) async throws -> String {
        guard let record = registryStore[account] else { throw ChatError.recordNotFound}
        return record
    }
}
