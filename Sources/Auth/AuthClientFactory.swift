import Foundation
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectPairing
import WalletConnectNetworking

public struct AuthClientFactory {

    public static func create(metadata: AppMetadata, account: Account?, projectId: String, networkingClient: NetworkingInteractor, pairingRegisterer: PairingRegisterer) -> AuthClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return AuthClientFactory.create(metadata: metadata, account: account, projectId: projectId, logger: logger, keyValueStorage: keyValueStorage, keychainStorage: keychainStorage, networkingClient: networkingClient, pairingRegisterer: pairingRegisterer, iatProvider: DefaultIATProvider())
    }

    static func create(metadata: AppMetadata, account: Account?, projectId: String, logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, networkingClient: NetworkingInteractor, pairingRegisterer: PairingRegisterer, iatProvider: IATProvider) -> AuthClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let history = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)
        let messageFormatter = SIWEMessageFormatter()
        let appRequestService = AppRequestService(networkingInteractor: networkingClient, kms: kms, appMetadata: metadata, logger: logger, iatProvader: iatProvider)
        let messageSigner = MessageSignerFactory.create(projectId: projectId)
        let appRespondSubscriber = AppRespondSubscriber(networkingInteractor: networkingClient, logger: logger, rpcHistory: history, signatureVerifier: messageSigner, pairingRegisterer: pairingRegisterer, messageFormatter: messageFormatter)
        let walletErrorResponder = WalletErrorResponder(networkingInteractor: networkingClient, logger: logger, kms: kms, rpcHistory: history)
        let walletRequestSubscriber = WalletRequestSubscriber(networkingInteractor: networkingClient, logger: logger, kms: kms, messageFormatter: messageFormatter, address: account?.address, walletErrorResponder: walletErrorResponder, pairingRegisterer: pairingRegisterer)
        let walletRespondService = WalletRespondService(networkingInteractor: networkingClient, logger: logger, kms: kms, rpcHistory: history, walletErrorResponder: walletErrorResponder)
        let pendingRequestsProvider = PendingRequestsProvider(rpcHistory: history)

        return AuthClient(appRequestService: appRequestService,
                          appRespondSubscriber: appRespondSubscriber,
                          walletRequestSubscriber: walletRequestSubscriber,
                          walletRespondService: walletRespondService,
                          account: account,
                          pendingRequestsProvider: pendingRequestsProvider,
                          logger: logger,
                          socketConnectionStatusPublisher: networkingClient.socketConnectionStatusPublisher,
                          pairingRegisterer: pairingRegisterer)
    }
}
