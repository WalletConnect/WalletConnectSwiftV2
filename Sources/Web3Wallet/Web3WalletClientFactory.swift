import Foundation

import Auth
import WalletConnectSign

public struct Web3WalletClientFactory {
    public static func create(
        metadata: AppMetadata,
        projectId: String,
        signerFactory: SignerFactory,
        networkingClient: NetworkingInteractor,
        pairingRegisterer: PairingRegisterer,
        pairingClient: PairingClient
    ) -> Web3WalletClient {
        let authClient = AuthClientFactory.create(
            metadata: metadata,
            projectId: projectId,
            signerFactory: signerFactory,
            networkingClient: networkingClient,
            pairingRegisterer: pairingRegisterer
        )
        
        let signClient = SignClientFactory.create(
            metadata: metadata,
            pairingClient: pairingClient,
            networkingClient: networkingClient
        )
        
        return Web3WalletClient(authClient: authClient, signClient: signClient)
    }
}
