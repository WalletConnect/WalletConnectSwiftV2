import Foundation

public struct MessageSignerFactory {

    public let signerFactory: SignerFactory

    public init(signerFactory: SignerFactory) {
        self.signerFactory = signerFactory
    }

    public func create() -> MessageSigner {
        return create(projectId: Networking.projectId)
    }

    public func create(projectId: String) -> MessageSigner {
        return MessageSigner(
            signer: signerFactory.createEthereumSigner(),
            messageFormatter: SIWECacaoFormatter()
        )
    }
}
