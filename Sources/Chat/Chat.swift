import Foundation
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectRelay
import Combine

class Chat {
    private var publishers = [AnyCancellable]()
    private let registry: Registry
    private let registryService: RegistryService
    private let messagingService: MessagingService
    private let invitationHandlingService: InvitationHandlingService
    private let inviteService: InviteService
    private let kms: KeyManagementService
    private let threadStore: CodableStore<Thread>
    private let messagesStore: CodableStore<Message>

    let socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>

    private var newThreadPublisherSubject = PassthroughSubject<Thread, Never>()
    public var newThreadPublisher: AnyPublisher<Thread, Never> {
        newThreadPublisherSubject.eraseToAnyPublisher()
    }

    private var invitePublisherSubject = PassthroughSubject<InviteEnvelope, Never>()
    public var invitePublisher: AnyPublisher<InviteEnvelope, Never> {
        invitePublisherSubject.eraseToAnyPublisher()
    }

    private var messagePublisherSubject = PassthroughSubject<Message, Never>()
    public var messagePublisher: AnyPublisher<Message, Never> {
        messagePublisherSubject.eraseToAnyPublisher()
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
        let jsonRpcHistory = JsonRpcHistory<ChatRequestParams>(logger: logger, keyValueStore: CodableStore<JsonRpcRecord>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.jsonRpcHistory.rawValue))
        let networkingInteractor = NetworkingInteractor(
            relayClient: relayClient,
            serializer: serialiser,
            logger: logger,
            jsonRpcHistory: jsonRpcHistory)
        let invitePayloadStore = CodableStore<RequestSubscriptionPayload>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.invite.rawValue)
        self.registryService = RegistryService(registry: registry, networkingInteractor: networkingInteractor, kms: kms, logger: logger, topicToInvitationPubKeyStore: topicToInvitationPubKeyStore)
        threadStore = CodableStore<Thread>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.threads.rawValue)
        self.invitationHandlingService = InvitationHandlingService(registry: registry,
                             networkingInteractor: networkingInteractor,
                                                                   kms: kms,
                                                                   logger: logger,
                                                                   topicToInvitationPubKeyStore: topicToInvitationPubKeyStore,
                                                                   invitePayloadStore: invitePayloadStore,
                                                                   threadsStore: threadStore)
        self.inviteService = InviteService(networkingInteractor: networkingInteractor, kms: kms, logger: logger)
        self.messagesStore = CodableStore<Message>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.messages.rawValue)
        self.messagingService = MessagingService(networkingInteractor: networkingInteractor, messagesStore: messagesStore, logger: logger)
        socketConnectionStatusPublisher = relayClient.socketConnectionStatusPublisher
        setUpEnginesCallbacks()
    }

    /// Registers a new record on Chat keyserver,
    /// record is a blockchain account with a client generated public key
    /// - Parameter account: CAIP10 blockchain account
    /// - Returns: public key
    public func register(account: Account) async throws -> String {
        try await registryService.register(account: account)
    }

    /// Queries the default keyserver with a blockchain account
    /// - Parameter account: CAIP10 blockachain account
    /// - Returns: public key associated with an account in chat's keyserver
    public func resolve(account: Account) async throws -> String {
        try await registry.resolve(account: account)
    }

    /// Sends a chat invite with opening message
    /// - Parameters:
    ///   - publicKey: publicKey associated with a peer
    ///   - openingMessage: oppening message for a chat invite
    public func invite(publicKey: String, openingMessage: String) async throws {
        // TODO - how to provide account?
        // in init or in invite method's params
        let tempAccount = Account("eip155:1:33e32e32")!
        try await inviteService.invite(peerPubKey: publicKey, openingMessage: openingMessage, account: tempAccount)
    }

    public func accept(inviteId: String) async throws {
        try await invitationHandlingService.accept(inviteId: inviteId)
    }

    public func reject(inviteId: String) async throws {

    }

    /// Sends a chat message to an active chat thread
    /// - Parameters:
    ///   - topic: thread topic
    ///   - message: chat message
    public func message(topic: String, message: String) async throws {
        try await messagingService.send(topic: topic, messageString: message)
    }

    /// To Ping peer client
    /// - Parameter topic: chat thread topic
    public func ping(topic: String) {
        fatalError("not implemented")
    }

    public func leave(topic: String) async throws {
        fatalError("not implemented")
    }

    public func getInvites(account: Account) -> [Invite] {
        fatalError("not implemented")
    }

    public func getThreads(account: Account) -> [Thread] {
        threadStore.getAll()
    }

    public func getMessages(topic: String) -> [Message] {
        messagesStore.getAll()
    }

    private func setUpEnginesCallbacks() {
        invitationHandlingService.onInvite = { [unowned self] inviteEnvelope in
            invitePublisherSubject.send(inviteEnvelope)
        }
        invitationHandlingService.onNewThread = { [unowned self] newThread in
            newThreadPublisherSubject.send(newThread)
        }
        inviteService.onNewThread = { [unowned self] newThread in
            newThreadPublisherSubject.send(newThread)
        }
        messagingService.onMessage = { [unowned self] message in
            messagePublisherSubject.send(message)
        }
    }
}

