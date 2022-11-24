import Foundation

public struct MessageSignerFactory {

    public let signerFactory: SignerFactory

    public init(signerFactory: SignerFactory) {
        self.signerFactory = signerFactory
    }

    public func create() -> MessageSigning & MessageSignatureVerifying {
        return create(projectId: Networking.projectId)
    }

    func create(projectId: String) -> MessageSigning & MessageSignatureVerifying {
        return MessageSigner(
            signer: signerFactory.createEthereum(),
            eip191Verifier: EIP191Verifier(signer: signerFactory.createEthereum()),
            eip1271Verifier: EIP1271Verifier(
                projectId: projectId,
                httpClient: HTTPNetworkClient(host: "rpc.walletconnect.com"),
                signer: signerFactory.createEthereum()
            )
        )
    }
}
