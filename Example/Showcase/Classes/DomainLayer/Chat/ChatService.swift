import Foundation
import Combine
import WalletConnectChat
import WalletConnectRelay

typealias Stream<T> = AsyncPublisher<AnyPublisher<T, Never>>

final class ChatService {

    private lazy var client: ChatClient = {
        guard let importAccount = accountStorage.importAccount else {
            fatalError("Error - you must call Chat.configure(_:) before accessing the shared instance.")
        }
        Chat.configure(account: importAccount.account)
        return Chat.instance
    }()

    private lazy var networking: NetworkingClient = {
        return Networking.instance
    }()

    private let accountStorage: AccountStorage

    init(accountStorage: AccountStorage) {
        self.accountStorage = accountStorage
    }

    var connectionPublisher: Stream<SocketConnectionStatus> {
        return networking.socketConnectionStatusPublisher.values
    }

    var threadPublisher: Stream<[WalletConnectChat.Thread]> {
        return client.threadsPublisher.values
    }

    var receivedInvitePublisher: Stream<[ReceivedInvite]> {
        return client.receivedInvitesPublisher.values
    }

    var sentInvitePublisher: Stream<[SentInvite]> {
        return client.sentInvitesPublisher.values
    }

    func messagePublisher(thread: WalletConnectChat.Thread) -> Stream<[Message]> {
        return client.messagesPublisher
            .map { $0.filter { $0.topic == thread.topic } }
            .eraseToAnyPublisher().values
    }

    func getMessages(thread: WalletConnectChat.Thread) -> [WalletConnectChat.Message] {
        client.getMessages(topic: thread.topic)
    }

    func getThreads() -> [WalletConnectChat.Thread] {
        client.getThreads()
    }

    func getReceivedInvites() -> [ReceivedInvite] {
        client.getReceivedInvites()
    }

    func sendMessage(topic: String, message: String) async throws {
        try await client.message(topic: topic, message: message)
    }

    func accept(invite: ReceivedInvite) async throws {
        try await client.accept(inviteId: invite.id)
    }

    func reject(invite: ReceivedInvite) async throws {
        try await client.reject(inviteId: invite.id)
    }

    func invite(inviterAccount: Account, inviteeAccount: Account, message: String) async throws {
        let inviteePublicKey = try await client.resolve(account: inviteeAccount)
        let invite = Invite(message: message, inviterAccount: inviterAccount, inviteeAccount: inviteeAccount, inviteePublicKey: inviteePublicKey)
        try await client.invite(invite: invite)
    }

    func register(account: Account, privateKey: String) async throws {
        _ = try await client.register(account: account) { message in
            let privateKey = Data(hex: privateKey)
            let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create()
            return try! signer.sign(message: message, privateKey: privateKey, type: .eip191)
        }
    }

    func resolve(account: Account) async throws -> String {
        return try await client.resolve(account: account)
    }
}
