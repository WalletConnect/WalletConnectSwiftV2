import Foundation
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectRelay
import Combine

public class ChatClient {
    private var publishers = [AnyCancellable]()
    private let registry: Registry
    private let registryService: RegistryService
    private let messagingService: MessagingService
    private let invitationHandlingService: InvitationHandlingService
    private let inviteService: InviteService
    private let leaveService: LeaveService
    private let resubscriptionService: ResubscriptionService
    private let kms: KeyManagementService
    private let threadStore: Database<Thread>
    private let messagesStore: Database<Message>
    private let invitePayloadStore: CodableStore<(RequestSubscriptionPayload)>

    public let socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>

    private var newThreadPublisherSubject = PassthroughSubject<Thread, Never>()
    public var newThreadPublisher: AnyPublisher<Thread, Never> {
        newThreadPublisherSubject.eraseToAnyPublisher()
    }

    private var invitePublisherSubject = PassthroughSubject<Invite, Never>()
    public var invitePublisher: AnyPublisher<Invite, Never> {
        invitePublisherSubject.eraseToAnyPublisher()
    }

    private var messagePublisherSubject = PassthroughSubject<Message, Never>()
    public var messagePublisher: AnyPublisher<Message, Never> {
        messagePublisherSubject.eraseToAnyPublisher()
    }

    public init(registry: Registry,
         relayClient: RelayClient,
         kms: KeyManagementService,
                logger: ConsoleLogging = ConsoleLogger(loggingLevel: .debug),
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
        self.invitePayloadStore = CodableStore<RequestSubscriptionPayload>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.invite.rawValue)
        self.registryService = RegistryService(registry: registry, networkingInteractor: networkingInteractor, kms: kms, logger: logger, topicToInvitationPubKeyStore: topicToInvitationPubKeyStore)
        threadStore = Database<Thread>(keyValueStorage: keyValueStorage, identifier: StorageDomainIdentifiers.threads.rawValue)
        self.resubscriptionService = ResubscriptionService(networkingInteractor: networkingInteractor, threadStore: threadStore, logger: logger)
        self.invitationHandlingService = InvitationHandlingService(registry: registry,
                             networkingInteractor: networkingInteractor,
                                                                   kms: kms,
                                                                   logger: logger,
                                                                   topicToInvitationPubKeyStore: topicToInvitationPubKeyStore,
                                                                   invitePayloadStore: invitePayloadStore,
                                                                   threadsStore: threadStore)
        self.inviteService = InviteService(
            networkingInteractor: networkingInteractor,
            kms: kms,
            threadStore: threadStore,
            logger: logger)
        self.leaveService = LeaveService()
        self.messagesStore = Database<Message>(keyValueStorage: keyValueStorage, identifier: StorageDomainIdentifiers.messages.rawValue)
        self.messagingService = MessagingService(
            networkingInteractor: networkingInteractor,
            messagesStore: messagesStore,
            threadStore: threadStore,
            logger: logger)
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
    ///   TODO - peerAccount should be derived
    public func invite(publicKey: String, peerAccount: Account, openingMessage: String, account: Account) async throws {
        try await inviteService.invite(peerPubKey: publicKey, peerAccount: peerAccount, openingMessage: openingMessage, account: account)
    }

    public func accept(inviteId: String) async throws {
        try await invitationHandlingService.accept(inviteId: inviteId)
    }

    public func reject(inviteId: String) async throws {
        try await invitationHandlingService.reject(inviteId: inviteId)
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
        try await leaveService.leave(topic: topic)
    }

    public func getInvites(account: Account) -> [Invite] {
        var invites = [Invite]()
        invitePayloadStore.getAll().forEach {
            guard case .invite(let invite) = $0.request.params else {return}
            invites.append(invite)
        }
        return invites
    }

    public func getThreads() async -> [Thread] {
        await threadStore.getAll()
    }

    public func getMessages(topic: String) async -> [Message] {
        await messagesStore.filter {$0.topic == topic} ?? []
    }

    private func setUpEnginesCallbacks() {
        invitationHandlingService.onInvite = { [unowned self] invite in
            invitePublisherSubject.send(invite)
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
