import Foundation

final class SyncClientFactory {

    static func create(networkInteractor: NetworkInteracting, bip44: BIP44Provider) -> SyncClient {
        let keychain = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return create(networkInteractor: networkInteractor, bip44: bip44, keychain: keychain)
    }

    static func create(networkInteractor: NetworkInteracting, bip44: BIP44Provider, keychain: KeychainStorageProtocol) -> SyncClient {
        let signatureStore = SyncSignatureStore(keychain: keychain)
        let kms = KeyManagementService(keychain: keychain)
        let deriviationService = SyncDerivationService(
            syncStorage: signatureStore,
            bip44: bip44,
            kms: kms
        )
        let indexStore = CodableStore<SyncRecord>(defaults: UserDefaults.standard, identifier: SyncStorageIdentifiers.index.identifier)
        let syncIndexStore = SyncIndexStore(store: indexStore)
        let historyStore = CodableStore<Int64>(defaults: UserDefaults.standard, identifier: SyncStorageIdentifiers.history.identifier)
        let syncHistoryStore = SyncHistoryStore(store: historyStore)
        let syncService = SyncService(
            networkInteractor: networkInteractor,
            derivationService: deriviationService,
            signatureStore: signatureStore,
            indexStore: syncIndexStore,
            historyStore: syncHistoryStore,
            logger: ConsoleLogger(loggingLevel: .debug)
        )
        return SyncClient(syncService: syncService, syncSignatureStore: signatureStore)
    }
}
