import Foundation

public final class ENSResolverFactory {

    public let crypto: CryptoProvider

    public init(crypto: CryptoProvider) {
        self.crypto = crypto
    }

    public func create() -> ENSResolver {
        return create(projectId: Networking.projectId)
    }

    public func create(projectId: String) -> ENSResolver {
        let httpClient = HTTPNetworkClient(host: "rpc.walletconnect.com")
        return ENSResolver(
            projectId: projectId,
            httpClient: httpClient,
            registry: ENSRegistryContract(
                // [Default ENS registry address](https://docs.ens.domains/ens-deployments)
                address: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",
                projectId: projectId,
                httpClient: httpClient
            ),
            crypto: crypto
        )
    }
}
