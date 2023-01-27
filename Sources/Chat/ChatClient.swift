import Foundation
import Combine

public class ChatClient {
    private var publishers = [AnyCancellable]()
    private let registry: Registry
    private let registryService: RegistryService
    private let messagingService: MessagingService
    private let accountService: AccountService
    private let invitationHandlingService: InvitationHandlingService
    private let inviteService: InviteService
    private let leaveService: LeaveService
    private let kms: KeyManagementService
    private let chatStorage: ChatStorage

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

    // MARK: - Initialization

    init(registry: Registry,
         registryService: RegistryService,
         messagingService: MessagingService,
         accountService: AccountService,
         invitationHandlingService: InvitationHandlingService,
         inviteService: InviteService,
         leaveService: LeaveService,
         kms: KeyManagementService,
         chatStorage: ChatStorage,
         socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>
    ) {
        self.registry = registry
        self.registryService = registryService
        self.messagingService = messagingService
        self.accountService = accountService
        self.invitationHandlingService = invitationHandlingService
        self.inviteService = inviteService
        self.leaveService = leaveService
        self.kms = kms
        self.chatStorage = chatStorage
        self.socketConnectionStatusPublisher = socketConnectionStatusPublisher

        setUpEnginesCallbacks()
    }

    // MARK: - Public interface

    /// Registers a new record on Chat keyserver,
    /// record is a blockchain account with a client generated public key
    /// - Parameter account: CAIP10 blockchain account
    /// - Returns: public key
    @discardableResult
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
    public func invite(peerAccount: Account, openingMessage: String) async throws {
        try await inviteService.invite(peerAccount: peerAccount, openingMessage: openingMessage)
    }

    public func accept(inviteId: Int64) async throws {
        try await invitationHandlingService.accept(inviteId: inviteId)
    }

    public func reject(inviteId: Int64) async throws {
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

    public func getInvites() -> [Invite] {
        return chatStorage.getInvites(account: accountService.currentAccount)
    }

    public func getThreads() -> [Thread] {
        return chatStorage.getThreads(account: accountService.currentAccount)
    }

    public func getMessages(topic: String) -> [Message] {
        return chatStorage.getMessages(topic: topic, account: accountService.currentAccount)
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
