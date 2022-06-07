
import Foundation
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectRelay
import Combine


class Chat {
    private var publishers = [AnyCancellable]()
    let registry: Registry
    let registryManager: RegistryManager
    let engine: Engine
    let kms: KeyManagementService
    
    let socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>
    
    var newThreadPublisherSubject = PassthroughSubject<Thread, Never>()
    public var newThreadPublisher: AnyPublisher<Thread, Never> {
        newThreadPublisherSubject.eraseToAnyPublisher()
    }
    
    var invitePublisherSubject = PassthroughSubject<Invite, Never>()
    public var invitePublisher: AnyPublisher<Invite, Never> {
        invitePublisherSubject.eraseToAnyPublisher()
    }

    init(registry: Registry,
         relayClient: RelayClient,
         kms: KeyManagementService,
         logger: ConsoleLogging = ConsoleLogger(loggingLevel: .off),
         keyValueStorage: KeyValueStorage) {
        let topicToInvitationPubKeyStore = CodableStore<String>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.topicToInvitationPubKey.rawValue)
        self.registry = registry
        self.kms = kms
        let serialiser = Serializer(kms: kms)
        let networkingInteractor = NetworkingInteractor(relayClient: relayClient, serializer: serialiser)
        let inviteStore = CodableStore<Invite>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.invite.rawValue)
        self.registryManager = RegistryManager(registry: registry, networkingInteractor: networkingInteractor, kms: kms, logger: logger, topicToInvitationPubKeyStore: topicToInvitationPubKeyStore)
        self.engine = Engine(registry: registry,
                             networkingInteractor: networkingInteractor,
                             kms: kms,
                             logger: logger,
                             topicToInvitationPubKeyStore: topicToInvitationPubKeyStore,
                             inviteStore: inviteStore,
                             threadsStore: CodableStore<Thread>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.threads.rawValue))
        socketConnectionStatusPublisher = relayClient.socketConnectionStatusPublisher
        setUpEnginesCallbacks()
    }
    
    /// Registers a new record on Chat keyserver,
    /// record is a blockchain account with a client generated public key
    /// - Parameter account: CAIP10 blockchain account
    /// - Returns: public key
    func register(account: Account) async throws -> String {
        try await registryManager.register(account: account)
    }
    
    /// Queries the default keyserver with a blockchain account
    /// - Parameter account: CAIP10 blockachain account
    /// - Returns: public key associated with an account in chat's keyserver
    func resolve(account: Account) async throws -> String {
        try await registry.resolve(account: account)
    }
    
    /// Sends a chat invite with opening message
    /// - Parameters:
    ///   - publicKey: publicKey associated with a peer
    ///   - openingMessage: oppening message for a chat invite
    func invite(publicKey: String, openingMessage: String) async throws {
        try await engine.invite(peerPubKey: publicKey, openingMessage: openingMessage)
    }
    
    func accept(inviteId: String) async throws {
        try await engine.accept(inviteId: inviteId)
    }
    
    /// Sends a chat message to an active chat thread
    /// - Parameters:
    ///   - topic: thread topic
    ///   - message: chat message
    func message(topic: String, message: String) {
        
    }
    
    /// To Ping peer client
    /// - Parameter topic: chat thread topic
    func ping(topic: String) {
        
    }
    
    private func setUpEnginesCallbacks() {
        engine.onInvite = { [unowned self] invite in
            invitePublisherSubject.send(invite)
        }
        engine.onNewThread = { [unowned self] newThread in
            newThreadPublisherSubject.send(newThread)
        }
    }
}

