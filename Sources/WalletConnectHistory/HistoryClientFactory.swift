import Foundation

class HistoryClientFactory {

    static func create() -> HistoryClient {
        let keychain = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return HistoryClientFactory.create(
            historyUrl: "https://history.walletconnect.com",
            relayUrl: "wss://relay.walletconnect.com",
            keychain: keychain
        )
    }

    static func create(historyUrl: String, relayUrl: String, keychain: KeychainStorageProtocol) -> HistoryClient {
        let clientIdStorage = ClientIdStorage(keychain: keychain)
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
