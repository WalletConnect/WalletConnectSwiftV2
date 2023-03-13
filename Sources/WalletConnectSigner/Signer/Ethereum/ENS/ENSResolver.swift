import Foundation

public actor ENSResolver {

    private let projectId: String
    private let httpClient: HTTPClient
    private let registry: ENSRegistryContract
    private let signer: EthereumSigner

    init(projectId: String, httpClient: HTTPClient, registry: ENSRegistryContract, signer: EthereumSigner) {
        self.projectId = projectId
        self.httpClient = httpClient
        self.registry = registry
        self.signer = signer
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

    public func resolveAddress(ens: String, blockchain: Blockchain) async throws -> String {
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

        return try await resolver.address(namehash: namehash)
    }
}

private extension ENSResolver {

    func namehash(_ name: String) -> Data {
        var result = [UInt8](repeating: 0, count: 32)
        let labels = name.split(separator: ".")
        for label in labels.reversed() {
            let labelHash = signer.keccak256(label.lowercased().rawRepresentation)
            result.append(contentsOf: labelHash)
            result = [UInt8](signer.keccak256(Data(result)))
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
