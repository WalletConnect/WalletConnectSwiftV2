import Foundation
import WalletConnectRelay

public struct MessageSignerFactory {

    public static func create(projectId: String) -> MessageSigner {
        return MessageSigner(
            signer: Signer(),
            eip191Verifier: EIP191Verifier(),
            eip1271Verifier: EIP1271Verifier(
                projectId: projectId,
                httpClient: HTTPClient(host: "rpc.walletconnect.com")
            )
        )
    }
}
