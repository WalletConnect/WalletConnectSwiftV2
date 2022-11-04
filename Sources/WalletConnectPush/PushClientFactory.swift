import Foundation

public struct PushClientFactory {

    static public func create(logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, networkingClient: NetworkingInteractor, pairingClient: PairingClient) -> PushClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let pushProposer = PushProposer(networkingInteractor: networkingClient, kms: kms, logger: logger)
        let proposalResponseSubscriber = ProposalResponseSubscriber(networkingInteractor: networkingClient, kms: kms, logger: logger)

        return PushClient(
            networkInteractor: networkingClient,
            logger: logger,
            kms: kms,
            pushProposer: pushProposer, proposalResponseSubscriber: proposalResponseSubscriber,
            pairingRegisterer: pairingClient
        )
    }
}
