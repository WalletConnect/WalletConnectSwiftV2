
import Foundation
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectRelay
import Combine


class Chat {
    private var publishers = [AnyCancellable]()
    let registry: Registry
    let registryManager: RegistryManager
    let invitationHandlingService: InvitationHandlingService
    let inviteService: InviteService
    let kms: KeyManagementService
    
    let socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>
    
    var newThreadPublisherSubject = PassthroughSubject<String, Never>()
    public var newThreadPublisher: AnyPublisher<String, Never> {
        newThreadPublisherSubject.eraseToAnyPublisher()
    }
    
    var invitePublisherSubject = PassthroughSubject<InviteEnvelope, Never>()
    public var invitePublisher: AnyPublisher<InviteEnvelope, Never> {
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
        let invitePayloadStore = CodableStore<RequestSubscriptionPayload>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.invite.rawValue)
        self.registryManager = RegistryManager(registry: registry, networkingInteractor: networkingInteractor, kms: kms, logger: logger, topicToInvitationPubKeyStore: topicToInvitationPubKeyStore)
        let codec = ChaChaPolyCodec()
        self.invitationHandlingService = InvitationHandlingService(registry: registry,
                             networkingInteractor: networkingInteractor,
                                                                   kms: kms,
                                                                   logger: logger,
                                                                   topicToInvitationPubKeyStore: topicToInvitationPubKeyStore,
                                                                   invitePayloadStore: invitePayloadStore,
                                                                   threadsStore: CodableStore<Thread>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.threads.rawValue), codec: codec)
        self.inviteService = InviteService(networkingInteractor: networkingInteractor, kms: kms, logger: logger, codec: codec)
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
        //TODO - how to provide account?
        // in init or in invite method's params
        let tempAccount = Account("eip155:1:33e32e32")!
        try await inviteService.invite(peerPubKey: publicKey, openingMessage: openingMessage, account: tempAccount)
    }
    
    func accept(inviteId: String) async throws {
        try await invitationHandlingService.accept(inviteId: inviteId)
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
        invitationHandlingService.onInvite = { [unowned self] inviteEnvelope in
            invitePublisherSubject.send(inviteEnvelope)
        }
        invitationHandlingService.onNewThread = { [unowned self] newThread in
            newThreadPublisherSubject.send(newThread)
        }
    }
}

