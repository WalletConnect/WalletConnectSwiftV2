import Foundation
import Chat
import WalletConnectKMS
import WalletConnectRelay
import WalletConnectUtils

class ChatFactory {

    static func create() -> ChatClient {
        let keychain = KeychainStorage(serviceIdentifier: "com.walletconnect.showcase")
        let client = HTTPClient(host: "keys.walletconnect.com")
        let registry = KeyserverRegistryProvider(client: client)
        return ChatClientFactory.create(
            registry: registry,
            relayClient: Relay.instance,
            kms: KeyManagementService(keychain: keychain),
            logger: ConsoleLogger(),
            keyValueStorage: UserDefaults.standard
        )
    }
}
