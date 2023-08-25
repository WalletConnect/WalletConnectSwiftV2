import Foundation

public struct Web3WalletClientFactory {
    public static func create(
        authClient: AuthClientProtocol,
        signClient: SignClientProtocol,
        pairingClient: PairingClientProtocol,
        pushClient: PushClientProtocol
    ) -> Web3WalletClient {
        return Web3WalletClient(
            authClient: authClient,
            signClient: signClient,
            pairingClient: pairingClient,
            pushClient: pushClient
        )
    }
}
