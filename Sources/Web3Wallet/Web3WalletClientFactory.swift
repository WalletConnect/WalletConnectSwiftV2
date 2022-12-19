import Foundation

import Auth
import WalletConnectSign

public struct Web3WalletClientFactory {
    public static func create(
        authClient: AuthClient,
        signClient: SignClient,
        pairingClient: PairingClient
    ) -> Web3WalletClient {
        return Web3WalletClient(authClient: authClient, signClient: signClient, pairingClient: pairingClient)
    }
}
