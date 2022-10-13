import Foundation
import Chat
import WalletConnectNetworking
import WalletConnectRelay
import WalletConnectKMS
import WalletConnectUtils

class ChatFactory {

    static func create() -> ChatClient {
        let keychain = KeychainStorage(serviceIdentifier: "com.walletconnect.showcase")
        let client = HTTPNetworkClient(host: "keys.walletconnect.com")
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
