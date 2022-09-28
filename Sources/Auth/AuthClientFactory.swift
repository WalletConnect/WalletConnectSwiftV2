import Foundation
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectPairing
import WalletConnectNetworking

public struct AuthClientFactory {

    public static func create(metadata: AppMetadata, account: Account?, relayClient: RelayClient) -> AuthClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return AuthClientFactory.create(metadata: metadata, account: account, logger: logger, keyValueStorage: keyValueStorage, keychainStorage: keychainStorage, relayClient: relayClient)
    }

    static func create(metadata: AppMetadata, account: Account?, logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, relayClient: RelayClient) -> AuthClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let serializer = Serializer(kms: kms)
        let history = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)
        let networkingInteractor = NetworkingInteractor(relayClient: relayClient, serializer: serializer, logger: logger, rpcHistory: history)
        let messageFormatter = SIWEMessageFormatter()
        let appRequestService = AppRequestService(networkingInteractor: networkingInteractor, kms: kms, appMetadata: metadata, logger: logger)
        let messageSigner = MessageSigner(signer: Signer())
        let appRespondSubscriber = AppRespondSubscriber(networkingInteractor: networkingInteractor, logger: logger, rpcHistory: history, signatureVerifier: messageSigner, messageFormatter: messageFormatter)
        let walletErrorResponder = WalletErrorResponder(networkingInteractor: networkingInteractor, logger: logger, kms: kms, rpcHistory: history)
        let walletRequestSubscriber = WalletRequestSubscriber(networkingInteractor: networkingInteractor, logger: logger, kms: kms, messageFormatter: messageFormatter, address: account?.address, walletErrorResponder: walletErrorResponder)
        let walletRespondService = WalletRespondService(networkingInteractor: networkingInteractor, logger: logger, kms: kms, rpcHistory: history, walletErrorResponder: walletErrorResponder)
        let pendingRequestsProvider = PendingRequestsProvider(rpcHistory: history)

        //TODO - fix this - singleton?
        let pairingClient = PairingClientFactory.create(relayClient: relayClient)

        return AuthClient(appRequestService: appRequestService,
                          appRespondSubscriber: appRespondSubscriber,
                          walletRequestSubscriber: walletRequestSubscriber,
                          walletRespondService: walletRespondService,
                          account: account,
                          pendingRequestsProvider: pendingRequestsProvider,
                          logger: logger,
                          socketConnectionStatusPublisher: relayClient.socketConnectionStatusPublisher,
                          pairingClient: pairingClient)
    }
}
