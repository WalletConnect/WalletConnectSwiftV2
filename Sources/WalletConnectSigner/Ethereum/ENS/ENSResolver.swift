import Foundation

public actor ENSResolver {

    private let projectId: String
    private let httpClient: HTTPClient
    private let registry: ENSRegistryContract
    private let crypto: CryptoProvider

    init(projectId: String, httpClient: HTTPClient, registry: ENSRegistryContract, crypto: CryptoProvider) {
        self.projectId = projectId
        self.httpClient = httpClient
        self.registry = registry
        self.crypto = crypto
    }

    public func resolveEns(account: Account) async throws -> String {
        let namehash = namehash(account.reversedDomain)
        let resolverAddaress = try await registry.resolver(
            namehash: namehash,
            chainId: account.blockchainIdentifier
        )
        let resolver = ENSResolverContract(
            address: resolverAddaress,
            projectId: projectId,
            chainId: account.blockchainIdentifier,
            httpClient: httpClient
        )
        return try await resolver.name(namehash: namehash)
    }

    public func resolveAddress(ens: String, blockchain: Blockchain) async throws -> Account {
        let namehash = namehash(ens)
        let resolverAddaress = try await registry.resolver(
            namehash: namehash,
            chainId: blockchain.absoluteString
        )
        let resolver = ENSResolverContract(
            address: resolverAddaress,
            projectId: projectId,
            chainId: blockchain.absoluteString,
            httpClient: httpClient
        )

        let address = try await resolver.address(namehash: namehash)
        let eip55 = EIP55(crypto: crypto).encode(address)

        guard let account = Account(blockchain: blockchain, address: eip55)
        else { throw Errors.invalidAccount }

        return account
    }
}

private extension ENSResolver {

    enum Errors: Error {
        case invalidAccount
    }

    func namehash(_ name: String) -> Data {
        var result = [UInt8](repeating: 0, count: 32)
        let labels = name.split(separator: ".")
        for label in labels.reversed() {
            let labelHash = crypto.keccak256(label.lowercased().rawRepresentation)
            result.append(contentsOf: labelHash)
            result = [UInt8](crypto.keccak256(Data(result)))
        }
        return Data(result)
    }
}

private extension Account {

    var reversedDomain: String {
        return address.lowercased()
            .replacingOccurrences(of: "0x", with: "") + ".addr.reverse"
    }
}
