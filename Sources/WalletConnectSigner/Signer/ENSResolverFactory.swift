import Foundation

public final class ENSResolverFactory {

    public let signerFactory: SignerFactory

    public init(signerFactory: SignerFactory) {
        self.signerFactory = signerFactory
    }

    public func create() -> ENSResolver {
        return create(projectId: Networking.projectId)
    }

    public func create(projectId: String) -> ENSResolver {
        return ENSResolver(
            // [Default ENS registry address](https://docs.ens.domains/ens-deployments)
            resolverAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",
            projectId: projectId,
            httpClient: HTTPNetworkClient(host: "rpc.walletconnect.com"),
            signer: signerFactory.createEthereumSigner()
        )
    }
}
