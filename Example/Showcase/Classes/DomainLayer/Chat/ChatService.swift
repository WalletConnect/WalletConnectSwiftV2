import Foundation
import Combine
import Chat
import WalletConnectUtils
import WalletConnectRelay

typealias Stream<T> = AsyncPublisher<AnyPublisher<T, Never>>

final class ChatService {

    private let client: ChatClient

    init(client: ChatClient) {
        self.client = client
    }

    var connectionPublisher: Stream<SocketConnectionStatus> {
        return client.socketConnectionStatusPublisher.values
    }

    var messagePublisher: Stream<Message> {
        return client.messagePublisher.values
    }

    var threadPublisher: Stream<Chat.Thread> {
        return client.newThreadPublisher.values
    }

    var invitePublisher: Stream<Invite> {
        return client.invitePublisher.values
    }

    func getMessages(thread: Chat.Thread) async -> [Chat.Message] {
        await client.getMessages(topic: thread.topic)
    }

    func getThreads() async -> [Chat.Thread] {
        await client.getThreads()
    }

    func getInvites(account: Account) async -> [Chat.Invite] {
        client.getInvites(account: account)
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

    func invite(peerPubkey publicKey: String, peerAccount: Account, message: String, selfAccount: Account) async throws {
        try await client.invite(publicKey: publicKey, peerAccount: peerAccount, openingMessage: message, account: selfAccount)
    }

    func register(account: Account) async throws {
        _ = try await client.register(account: account)
    }

    func resolve(account: Account) async throws -> String {
        return try await client.resolve(account: account)
    }
}
