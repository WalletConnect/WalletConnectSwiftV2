import Foundation

class HistoryClientFactory {

    static func create() -> HistoryClient {
        let keychain = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        let keyValueStorage = UserDefaults.standard
        let logger = ConsoleLogger()
        return HistoryClientFactory.create(
            historyUrl: "https://history.walletconnect.com",
            relayUrl: "wss://relay.walletconnect.com",
            keyValueStorage: keyValueStorage,
            keychain: keychain,
            logger: logger
        )
    }

    static func create(historyUrl: String, relayUrl: String, keyValueStorage: KeyValueStorage, keychain: KeychainStorageProtocol, logger: ConsoleLogging) -> HistoryClient {
        let clientIdStorage = ClientIdStorage(defaults: keyValueStorage, keychain: keychain, logger: logger)
        let kms = KeyManagementService(keychain: keychain)
        let serializer = Serializer(kms: kms, logger: ConsoleLogger(prefix: "🔐", loggingLevel: .off))
        let historyNetworkService = HistoryNetworkService(clientIdStorage: clientIdStorage)
        return HistoryClient(
            historyUrl: historyUrl,
            relayUrl: relayUrl,
            serializer: serializer,
            historyNetworkService: historyNetworkService
        )
    }
}
