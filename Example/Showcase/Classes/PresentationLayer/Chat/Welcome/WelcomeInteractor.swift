import Foundation
import Combine

import WalletConnectRelay
import WalletConnectPairing
import Auth

final class WelcomeInteractor {
    private var disposeBag = Set<AnyCancellable>()
    
    private let chatService: ChatService
    private let accountStorage: AccountStorage
    
    var authClient: AuthClient?

    init(chatService: ChatService, accountStorage: AccountStorage) {
        self.chatService = chatService
        self.accountStorage = accountStorage
    }

    var account: Account? {
        return accountStorage.account
    }

    func isAuthorized() -> Bool {
        accountStorage.account != nil
    }

    func trackConnection() -> Stream<SocketConnectionStatus> {
        return chatService.connectionPublisher
    }
    
    func generateUri() async -> WalletConnectURI {
        let appPairingClient = makeClient(prefix: "🤡")
        return try! await appPairingClient.create()
    }
    
    func makeClient(prefix: String) -> PairingClient {
        let keychain = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        let keyValueStorage = RuntimeKeyValueStorage()

        let relayLogger = ConsoleLogger(suffix: prefix + " [Relay]", loggingLevel: .debug)
        let pairingLogger = ConsoleLogger(suffix: prefix + " [Pairing]", loggingLevel: .debug)
        let networkingLogger = ConsoleLogger(suffix: prefix + " [Networking]", loggingLevel: .debug)
        let authLogger = ConsoleLogger(suffix: prefix + " [Auth]", loggingLevel: .debug)

        let relayClient = RelayClient(
            relayHost: InputConfig.relayHost,
            projectId: InputConfig.projectId,
            keyValueStorage: RuntimeKeyValueStorage(),
            keychainStorage: keychain,
            socketFactory: SocketFactory(),
            logger: relayLogger
        )

        let networkingClient = NetworkingClientFactory.create(
            relayClient: relayClient,
            logger: networkingLogger,
            keychainStorage: keychain,
            keyValueStorage: keyValueStorage
        )

        let pairingClient = PairingClientFactory.create(
            logger: pairingLogger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            networkingClient: networkingClient
        )
        
        authClient = AuthClientFactory.create(
            metadata: AppMetadata(name: "chatapp", description: "", url: "", icons: [""]),
            projectId: InputConfig.projectId,
            signerFactory: DefaultSignerFactory(),
            networkingClient: networkingClient,
            pairingRegisterer: pairingClient
        )
        
        authClient?.authResponsePublisher.sink { (_, result) in
            guard case .success = result else {
                return
            }
            print(result)
        }
        .store(in: &disposeBag)

        return pairingClient
    }
}

protocol IATProvider {
    var iat: String { get }
}

struct DefaultIATProvider: IATProvider {
    var iat: String {
        return ISO8601DateFormatter().string(from: Date())
    }
}
