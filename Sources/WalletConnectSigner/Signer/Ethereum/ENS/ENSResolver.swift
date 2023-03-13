import Foundation

public actor ENSResolver {

    private let resolverAddress: String
    private let projectId: String
    private let httpClient: HTTPClient
    private let signer: EthereumSigner

    init(resolverAddress: String, projectId: String, httpClient: HTTPClient, signer: EthereumSigner) {
        self.resolverAddress = resolverAddress
        self.projectId = projectId
        self.httpClient = httpClient
        self.signer = signer
    }

    public func resolve(account: Account) async throws -> String {
        let registry = ENSRegistryContract(
            address: resolverAddress,
            projectId: projectId,
            chainId: account.blockchainIdentifier,
            httpClient: httpClient
        )
        let reversedDomain = account.address.lowercased()
            .replacingOccurrences(of: "0x", with: "") + ".addr.reverse"
        let namehash = namehash(reversedDomain)
        let resolverAddaress = try await registry.resolver(namehash: namehash)
        let resolver = ENSResolverContract(
            address: resolverAddaress,
            projectId: projectId,
            chainId: account.blockchainIdentifier,
            httpClient: httpClient
        )
        return try await resolver.name(namehash: namehash)
    }
}

private extension ENSResolver {

    func namehash(_ name: String) -> Data {
        var result = [UInt8](repeating: 0, count: 32)
        let labels = name.split(separator: ".")
        for label in labels.reversed() {
            let labelHash = signer.keccak256(normalizeLabel(label).rawRepresentation)
            result.append(contentsOf: labelHash)
            result = [UInt8](signer.keccak256(Data(result)))
        }
        return Data(result)
    }

    func normalizeLabel<S: StringProtocol>(_ label: S) -> String {
        // NOTE: this is NOT a [EIP-137](https://eips.ethereum.org/EIPS/eip-137) compliant implementation
        // TODO: properly implement domain name encoding via [UTS #46](https://unicode.org/reports/tr46/)
        return label.lowercased()
    }
}
