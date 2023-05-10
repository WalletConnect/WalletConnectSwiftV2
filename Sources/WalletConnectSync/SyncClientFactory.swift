import Foundation

final class SyncClientFactory {

    static func create(networkInteractor: NetworkingInteractor, crypto: CryptoProvider) -> SyncClient {
        let keychain = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return create(networkInteractor: networkInteractor, crypto: crypto, keychain: keychain)
    }

    static func create(networkInteractor: NetworkingInteractor, crypto: CryptoProvider, keychain: KeychainStorageProtocol) -> SyncClient {
        let signatureStore = SyncSignatureStore(keychain: keychain)
        let kms = KeyManagementService(keychain: keychain)
        let deriviationService = SyncDerivationService(
            syncStorage: signatureStore,
            crypto: crypto,
            kms: kms
        )
        let indexStore = CodableStore<SyncRecord>(defaults: UserDefaults.standard, identifier: SyncStorageIdentifiers.index.identifier)
        let syncIndexStore = SyncIndexStore(store: indexStore)
        let syncService = SyncService(
            networkInteractor: networkInteractor,
            derivationService: deriviationService,
            signatureStore: signatureStore,
            indexStore: syncIndexStore,
            logger: ConsoleLogger(loggingLevel: .debug)
        )
        return SyncClient(syncService: syncService, syncSignatureStore: signatureStore)
    }
}
