import Foundation

public struct MessageSignerFactory {

    public let signerFactory: SignerFactory

    public init(signerFactory: SignerFactory) {
        self.signerFactory = signerFactory
    }

    public func create() -> CacaoMessageSigner {
        return create(projectId: Networking.projectId)
    }

    public func create(projectId: String) -> CacaoMessageSigner {
        return MessageSigner(
            signer: signerFactory.createEthereumSigner(),
            eip191Verifier: EIP191Verifier(signer: signerFactory.createEthereumSigner()),
            eip1271Verifier: EIP1271Verifier(
                projectId: projectId,
                httpClient: HTTPNetworkClient(host: "rpc.walletconnect.com"),
                signer: signerFactory.createEthereumSigner()
            ),
            messageFormatter: SIWECacaoFormatter()
        )
    }
}
