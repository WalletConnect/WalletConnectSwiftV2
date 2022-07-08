import Foundation
import Chat
import WalletConnectKMS
import WalletConnectRelay

class ChatFactory {

    static func create() -> ChatClient {
        let relayHost = "relay.walletconnect.com"
        let projectId = "8ba9ee138960775e5231b70cc5ef1c3a"
        let keychain = KeychainStorage(serviceIdentifier: "com.walletconnect.showcase")
        let client = HTTPClient(host: relayHost)
        let registry = KeyserverRegistryProvider(client: client)
        let relayClient = RelayClient(relayHost: relayHost, projectId: projectId, keychainStorage: keychain, socketFactory: SocketFactory())
        return ChatClient(
            registry: registry,
            relayClient: relayClient,
            kms: KeyManagementService(keychain: keychain),
            keyValueStorage: UserDefaults.standard
        )
    }
}
