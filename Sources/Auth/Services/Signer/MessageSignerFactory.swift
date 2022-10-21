import Foundation
import WalletConnectNetworking

public struct MessageSignerFactory {

    public static func create() -> MessageSigning & MessageSignatureVerifying {
        return create(projectId: Networking.projectId)
    }

    static func create(projectId: String) -> MessageSigning & MessageSignatureVerifying {
        return MessageSigner(
            signer: Signer(),
            eip191Verifier: EIP191Verifier(),
            eip1271Verifier: EIP1271Verifier(
                projectId: projectId,
                httpClient: HTTPNetworkClient(host: "rpc.walletconnect.com")
            )
        )
    }
}
