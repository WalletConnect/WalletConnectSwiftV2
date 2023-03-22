import Foundation
import Combine

public class ChatClient {
    private var publishers = [AnyCancellable]()
    private let identityClient: IdentityClient
    private let messagingService: MessagingService
    private let accountService: AccountService
    private let resubscriptionService: ResubscriptionService
    private let invitationHandlingService: InvitationHandlingService
    private let inviteService: InviteService
    private let leaveService: LeaveService
    private let kms: KeyManagementService
    private let chatStorage: ChatStorage

    public let socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>

    public var messagesPublisher: AnyPublisher<[Message], Never> {
        return chatStorage.messagesPublisher
    }

    public var receivedInvitesPublisher: AnyPublisher<[ReceivedInvite], Never> {
        return chatStorage.receivedInvitesPublisher
    }

    public var sentInvitesPublisher: AnyPublisher<[SentInvite], Never> {
        return chatStorage.sentInvitesPublisher
    }

    public var threadsPublisher: AnyPublisher<[Thread], Never> {
        return chatStorage.threadsPublisher
    }

    public var newMessagePublisher: AnyPublisher<Message, Never> {
        return chatStorage.newMessagePublisher
    }

    public var newReceivedInvitePublisher: AnyPublisher<ReceivedInvite, Never> {
        return chatStorage.newReceivedInvitePublisher
    }

    public var newSentInvitePublisher: AnyPublisher<SentInvite, Never> {
        return chatStorage.newSentInvitePublisher
    }

    public var newThreadPublisher: AnyPublisher<Thread, Never> {
        return chatStorage.newThreadPublisher
    }

    public var acceptPublisher: AnyPublisher<(String, SentInvite), Never> {
        return chatStorage.acceptPublisher
    }

    public var rejectPublisher: AnyPublisher<SentInvite, Never> {
        return chatStorage.rejectPublisher
    }

    // MARK: - Initialization

    init(identityClient: IdentityClient,
         messagingService: MessagingService,
         accountService: AccountService,
         resubscriptionService: ResubscriptionService,
         invitationHandlingService: InvitationHandlingService,
         inviteService: InviteService,
         leaveService: LeaveService,
         kms: KeyManagementService,
         chatStorage: ChatStorage,
         socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>
    ) {
        self.identityClient = identityClient
        self.messagingService = messagingService
        self.accountService = accountService
        self.resubscriptionService = resubscriptionService
        self.invitationHandlingService = invitationHandlingService
        self.inviteService = inviteService
        self.leaveService = leaveService
        self.kms = kms
        self.chatStorage = chatStorage
        self.socketConnectionStatusPublisher = socketConnectionStatusPublisher
    }

    // MARK: - Public interface

    /// Registers a blockchain account with an identity key if not yet registered on this client
    /// Registers invite key if not yet registered on this client and starts listening on invites if private is false
    /// - Parameter onSign: Callback for signing CAIP-122 message to verify blockchain account ownership
    /// - Returns: Returns the public identity key
    @discardableResult
    public func register(account: Account,
        isPrivate: Bool = false,
        onSign: @escaping SigningCallback
    ) async throws -> String {
        let publicKey = try await identityClient.register(account: account, onSign: onSign)

        accountService.setAccount(account)

        guard !isPrivate else {
            return publicKey
        }

        try await goPublic(account: account)

        return publicKey
    }

    /// Unregisters a blockchain account with previously registered identity key
    /// Must not unregister invite key but must stop listening for invites
    /// - Parameter onSign: Callback for signing CAIP-122 message to verify blockchain account ownership
    public func unregister(account: Account, onSign: @escaping SigningCallback) async throws {
        try await identityClient.unregister(account: account, onSign: onSign)
    }

    /// Queries the keyserver with a blockchain account
    /// - Parameter account: CAIP10 blockachain account
    /// - Returns: Returns the invite key
    public func resolve(account: Account) async throws -> String {
        try await identityClient.resolveInvite(account: account)
    }

    /// Sends a chat invite
    /// Creates and stores SentInvite with `pending` state
    /// - Parameter invite: An Invite object
    /// - Returns: Returns an invite id
    @discardableResult
    public func invite(invite: Invite) async throws -> Int64 {
        return try await inviteService.invite(invite: invite)
    }

    /// Unregisters an invite key from keyserver
    /// Stops listening for invites
    /// - Parameter account: CAIP10 blockachain account
    public func goPrivate(account: Account) async throws {
        let inviteKey = try await identityClient.goPrivate(account: account)
        resubscriptionService.unsubscribeFromInvites(inviteKey: inviteKey)
    }

    /// Registers an invite key if not yet registered on this client from keyserver
    /// Starts listening for invites
    /// - Parameter account: CAIP10 blockachain account
    /// - Returns: The public invite key
    public func goPublic(account: Account) async throws {
        let inviteKey = try await identityClient.goPublic(account: account)
        try await resubscriptionService.subscribeForInvites(inviteKey: inviteKey)
    }

    /// Accepts a chat invite by id from account specified as inviteeAccount in Invite
    /// - Parameter inviteId: Invite id
    /// - Returns: Thread topic
    @discardableResult
    public func accept(inviteId: Int64) async throws -> String {
        return try await invitationHandlingService.accept(inviteId: inviteId)
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

    public func getReceivedInvites() -> [ReceivedInvite] {
        return chatStorage.getReceivedInvites(account: accountService.currentAccount)
    }

    public func getSentInvites() -> [SentInvite] {
        return chatStorage.getSentInvites(account: accountService.currentAccount)
    }

    public func getThreads() -> [Thread] {
        return chatStorage.getThreads(account: accountService.currentAccount)
    }

    public func getMessages(topic: String) -> [Message] {
        return chatStorage.getMessages(topic: topic, account: accountService.currentAccount)
    }
}
