import Foundation
import Combine
import WalletConnectChat
import WalletConnectRelay

typealias Stream<T> = AsyncPublisher<AnyPublisher<T, Never>>

final class ChatService {

    private lazy var client: ChatClient = {
        guard let account = accountStorage.account else {
            fatalError("Error - you must call Chat.configure(_:) before accessing the shared instance.")
        }
        Chat.configure(account: account)
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

    var messagePublisher: Stream<Message> {
        return client.messagePublisher.values
    }

    var threadPublisher: Stream<WalletConnectChat.Thread> {
        return client.newThreadPublisher.values
    }

    var invitePublisher: Stream<Invite> {
        return client.invitePublisher.values
    }

    func getMessages(thread: WalletConnectChat.Thread) -> [WalletConnectChat.Message] {
        client.getMessages(topic: thread.topic)
    }

    func getThreads() -> [WalletConnectChat.Thread] {
        client.getThreads()
    }

    func getInvites() -> [WalletConnectChat.Invite] {
        client.getInvites()
    }

    func sendMessage(topic: String, message: String) async throws {
        try await client.message(topic: topic, message: message)
    }

    func accept(invite: Invite) async throws {
        try await client.accept(inviteId: invite.id)
    }

    func reject(invite: Invite) async throws {
        try await client.reject(inviteId: invite.id)
    }

    func invite(peerAccount: Account, message: String) async throws {
        try await client.invite(peerAccount: peerAccount, openingMessage: message)
    }

    func register(account: Account) async throws {
        _ = try await client.register(account: account)
    }

    func resolve(account: Account) async throws -> String {
        return try await client.resolve(account: account)
    }
}
