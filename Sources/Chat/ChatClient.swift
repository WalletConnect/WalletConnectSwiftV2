import Foundation
import Combine

public class ChatClient {
    private var publishers = [AnyCancellable]()
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

    init(registryService: RegistryService,
         messagingService: MessagingService,
         accountService: AccountService,
         invitationHandlingService: InvitationHandlingService,
         inviteService: InviteService,
         leaveService: LeaveService,
         kms: KeyManagementService,
         chatStorage: ChatStorage,
         socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>
    ) {
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

    /// Registers a blockchain account with an identity key if not yet registered on this client
    /// Registers invite key if not yet registered on this client and starts listening on invites if private is false
    /// - Parameter onSign: Callback for signing CAIP-122 message to verify blockchain account ownership
    /// - Returns: Returns the public identity key
    @discardableResult
    public func register(account: Account,
        isPrivate: Bool = false,
        onSign: (String) -> CacaoSignature
    ) async throws -> String {
        return try await registryService.register(
            account: account,
            isPrivate: isPrivate,
            onSign: onSign
        )
    }

    /// Unregisters a blockchain account with previously registered identity key
    /// Must not unregister invite key but must stop listening for invites
    /// - Parameter onSign: Callback for signing CAIP-122 message to verify blockchain account ownership
    public func unregister(account: Account,
        onSign: (String) -> CacaoSignature
    ) async throws {
        fatalError("Not implemented")
    }

    /// Queries the keyserver with a blockchain account
    /// - Parameter account: CAIP10 blockachain account
    /// - Returns: Returns the invite key
    public func resolve(account: Account) async throws -> String {
        try await registryService.resolve(account: account)
    }

    /// Sends a chat invite
    /// Creates and stores SentInvite with `pending` state
    /// - Parameter invite: An Invite object
    /// - Returns: Returns an invite id
    public func invite(invite: Invite) async throws -> Int64 {
        fatalError("TODO: Implement me")
//        try await inviteService.invite(peerAccount: peerAccount, openingMessage: openingMessage)
    }

    /// Unregisters an invite key from keyserver
    /// Stops listening for invites
    /// - Parameter account: CAIP10 blockachain account
    public func goPrivate(account: Account) async throws {
        fatalError("Not implemented")
    }

    /// Registers an invite key if not yet registered on this client from keyserver
    /// Starts listening for invites
    /// - Parameter account: CAIP10 blockachain account
    /// - Returns: The public invite key
    public func goPublic(account: Account) async throws {
        fatalError("Not implemented")
    }

    /// Accepts a chat invite by id from account specified as inviteeAccount in Invite
    /// - Parameter inviteId: Invite id
    /// - Returns: Thread topic
    public func accept(inviteId: Int64) async throws -> String {
        fatalError("TODO: Implement me")
        try await invitationHandlingService.accept(inviteId: inviteId)
    }

    /// Rejects a chat invite by id from account specified as inviteeAccount in Invite
    /// - Parameter inviteId: Invite id
    public func reject(inviteId: Int64) async throws {
        try await invitationHandlingService.reject(inviteId: inviteId)
    }

    /// Sends a chat message to an active chat thread from account specified as selfAccount in Thread
    /// - Parameters:
    ///   - topic: thread topic
    ///   - message: chat message
    public func message(topic: String, message: String) async throws {
        try await messagingService.send(topic: topic, messageString: message)
    }

    /// Ping its peer to evaluate if it's currently online
    /// - Parameter topic: chat thread topic
    public func ping(topic: String) {
        fatalError("not implemented")
    }

    /// Leaves a chat thread and stops receiving messages
    /// - Parameter topic: chat thread topic
    public func leave(topic: String) async throws {
        try await leaveService.leave(topic: topic)
    }

    /// Sets peer account with public key
    /// - Parameter account: CAIP10 blockachain account
    /// - Parameter publicKey: Account associated publicKey hex string
    public func setContact(account: Account, publicKey: String) async throws {
        fatalError("not implemented")
    }

    public func getReceivedInvites() -> [Invite] {
        return chatStorage.getInvites(account: accountService.currentAccount)
    }

    public func getSentInvites() -> [Invite] {
        fatalError("not implemented")
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
