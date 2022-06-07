
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
    
    func register(account: Account) async throws {
        try await registryManager.register(account: account)
    }
    
    /// Queries the default keyserver with a blockchain account
    /// - Parameter account: CAIP10 blockachain account
    /// - Returns: public key associated with an account in chat's keyserver
    func resolve(account: Account) async throws -> String {
        try await registry.resolve(account: account)
    }
    
    func invite(publicKey: String, oppeningMessage: String) async throws {
//        try await engine.invite(account: account)
    }
    
    func accept(inviteId: String) async throws {
        try await engine.accept(inviteId: inviteId)
    }
    
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

