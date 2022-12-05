import Foundation
import WalletConnectUtils
import WalletConnectEcho

public struct WalletPushClientFactory {

    public static func create(networkInteractor: NetworkInteracting, pairingRegisterer: PairingRegisterer, echoClient: EchoClient) -> WalletPushClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return WalletPushClientFactory.create(
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            networkInteractor: networkInteractor,
            pairingRegisterer: pairingRegisterer,
            echoClient: echoClient
        )
    }

    static func create(logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, networkInteractor: NetworkInteracting, pairingRegisterer: PairingRegisterer, echoClient: EchoClient) -> WalletPushClient {
        let kms = KeyManagementService(keychain: keychainStorage)

        let history = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)

        let proposeResponder = ProposeResponder(networkingInteractor: networkInteractor, logger: logger, kms: kms, rpcHistory: history)
        return WalletPushClient(
            logger: logger,
            kms: kms,
            echoRegisterer: echoClient,
            pairingRegisterer: pairingRegisterer,
            proposeResponder: proposeResponder
        )
    }
}
