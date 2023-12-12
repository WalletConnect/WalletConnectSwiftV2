import Foundation

public struct Web3WalletClientFactory {
    public static func create(
        authClient: AuthClientProtocol,
        signClient: SignClientProtocol,
        pairingClient: PairingClientProtocol,
        pushClient: PushClientProtocol
    ) -> Web3WalletClient {
        return Web3WalletClient(
            signClient: signClient,
            pairingClient: pairingClient,
            pushClient: pushClient
        )
    }
}
