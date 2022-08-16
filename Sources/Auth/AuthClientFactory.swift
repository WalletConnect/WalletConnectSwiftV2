import Foundation
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectPairing

public struct AuthClientFactory {

    public static func create(metadata: AppMetadata, account: Account, relayClient: RelayClient) -> AuthClient {

        let keyValueStorage = UserDefaults.standard
        let historyStorage = CodableStore<RPCHistory.Record>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.jsonRpcHistory.rawValue)

        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        let pairingStore = PairingStorage(storage: SequenceStore<WCPairing>(store: .init(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.pairings.rawValue)))


        let logger = ConsoleLogger(loggingLevel: .off)
        let kms = KeyManagementService(keychain: keychainStorage)
        let serializer = Serializer(kms: kms)
        let history = RPCHistory(keyValueStore: historyStorage)
        let networkingInteractor = NetworkingInteractor(relayClient: relayClient, serializer: serializer, rpcHistory: history)


        let appPairService = AppPairService(networkingInteractor: networkingInteractor, kms: kms, pairingStorage: <#T##WCPairingStorage#>)
        let appRequestService = AppRequestService(networkingInteractor: networkingInteractor, kms: kms, appMetadata: metadata)
        let appRespondSubscriber = AppRespondSubscriber(networkingInteractor: networkingInteractor, logger: <#T##ConsoleLogging#>, rpcHistory: <#T##RPCHistory#>)networkingInteractor
        let walletPairService = WalletPairService(networkingInteractor: networkingInteractor, kms: kms, pairingStorage: <#T##WCPairingStorage#>)
        let walletRequestSubscriber = WalletRequestSubscriber(networkingInteractor: networkingInteractor, logger: <#T##ConsoleLogging#>, messageFormatter: <#T##SIWEMessageFormatting#>, address: account.address)
        let walletRespondService = WalletRespondService(networkingInteractor: networkingInteractor, logger: <#T##ConsoleLogging#>, kms: kms, rpcHistory: <#T##RPCHistory#>)
        let account = account
        let pendingRequestsProvider =
        let cleanupService =
        let logger =
        let pairingStorage =

        return AuthClient(appPairService: <#T##AppPairService#>,
                          appRequestService: <#T##AppRequestService#>,
                          appRespondSubscriber: <#T##AppRespondSubscriber#>,
                          walletPairService: <#T##WalletPairService#>,
                          walletRequestSubscriber: <#T##WalletRequestSubscriber#>,
                          walletRespondService: <#T##WalletRespondService#>,
                          account: <#T##Account?#>,
                          pendingRequestsProvider: <#T##PendingRequestsProvider#>,
                          cleanupService: <#T##CleanupService#>,
                          logger: <#T##ConsoleLogging#>,
                          pairingStorage: <#T##WCPairingStorage#>)
    }
}
