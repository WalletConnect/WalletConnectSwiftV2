import Foundation
import Combine
import WalletConnectChat
import WalletConnectRelay
import WalletConnectSign

typealias Stream<T> = AnyPublisher<T, Never>

final class ChatService {

    private var client: ChatClient = {
        Chat.configure(bip44: DefaultBIP44Provider())
        return Chat.instance
    }()

    private lazy var networking: NetworkingClient = {
        return Networking.instance
    }()

    var connectionPublisher: Stream<SocketConnectionStatus> {
        return networking.socketConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    var threadPublisher: Stream<[WalletConnectChat.Thread]> {
        return client.threadsPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    var receivedInvitePublisher: Stream<[ReceivedInvite]> {
        return client.receivedInvitesPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    var sentInvitePublisher: Stream<[SentInvite]> {
        return client.sentInvitesPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func messagePublisher(thread: WalletConnectChat.Thread) -> Stream<[Message]> {
        return client.messagesPublisher
            .map {
                $0.filter { $0.topic == thread.topic }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getMessages(thread: WalletConnectChat.Thread) -> [WalletConnectChat.Message] {
        client.getMessages(topic: thread.topic)
    }

    func getThreads(account: Account) -> [WalletConnectChat.Thread] {
        return client.getThreads(account: account)
    }

    func getReceivedInvites(account: Account) -> [ReceivedInvite] {
        return client.getReceivedInvites(account: account)
    }

    func getSentInvites(account: Account) -> [SentInvite] {
        return client.getSentInvites(account: account)
    }

    func setupSubscriptions(account: Account) {
        try! client.setupSubscriptions(account: account)
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

    func goPublic(account: Account) async throws {
        try await client.goPublic(account: account)
    }

    func invite(inviterAccount: Account, inviteeAccount: Account, message: String) async throws {
        let inviteePublicKey = try await client.resolve(account: inviteeAccount)
        let invite = Invite(message: message, inviterAccount: inviterAccount, inviteeAccount: inviteeAccount, inviteePublicKey: inviteePublicKey)
        try await client.invite(invite: invite)
    }

    func register(account: Account, importAccount: ImportAccount) async throws {
        _ = try await client.register(account: account) { message in
            return await self.onSign(message: message, importAccount: importAccount)
        }
    }

    func unregister(account: Account, importAccount: ImportAccount) async throws {
        try await client.unregister(account: account) { message in
            return await self.onSign(message: message, importAccount: importAccount)
        }
    }

    func goPrivate(account: Account) async throws {
        try await client.goPrivate(account: account)
    }

    func resolve(account: Account) async throws -> String {
        return try await client.resolve(account: account)
    }
}

private extension ChatService {

    func onSign(message: String, importAccount: ImportAccount) async -> SigningResult {
        switch importAccount {
        case .swift, .kotlin, .js, .custom:
            return .signed(onSign(message: message, privateKey: importAccount.privateKey))
        case .web3Modal(let account, let topic):
            return await onWalletConnectModalSign(message: message, account: account, topic: topic)
        }
    }

    func onSign(message: String, privateKey: String) -> CacaoSignature {
        let privateKey = Data(hex: privateKey)
        let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create()
        return try! signer.sign(message: message, privateKey: privateKey, type: .eip191)
    }

    func onWalletConnectModalSign(message: String, account: Account, topic: String) async -> SigningResult {
        guard let session = Sign.instance.getSessions().first(where: { $0.topic == topic }) else { return .rejected }

        do {
            let request = makeRequest(session: session, message: message, account: account)
            try await Sign.instance.request(params: request)

            let signature: CacaoSignature = try await withCheckedThrowingContinuation { continuation in
                var cancellable: AnyCancellable?
                cancellable = Sign.instance.sessionResponsePublisher
                    .sink { response in
                        defer { cancellable?.cancel() }
                        switch response.result {
                        case .response(let value):
                            do {
                                let string = try value.get(String.self)
                                let signature = CacaoSignature(t: .eip191, s: string.deleting0x())
                                continuation.resume(returning: signature)
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        case .error(let error):
                            continuation.resume(throwing: error)
                        }
                    }
            }

            return .signed(signature)
        } catch {
            return .rejected
        }
    }

    func makeRequest(session: WalletConnectSign.Session, message: String, account: Account) -> Request {
        return Request(
            topic: session.topic,
            method: "personal_sign",
            params: AnyCodable(["0x" + message.data(using: .utf8)!.toHexString(), account.address]),
            chainId: Blockchain("eip155:1")!
        )
    }
}

fileprivate extension String {

    func deleting0x() -> String {
        var string = self
        if starts(with: "0x") {
            string.removeFirst(2)
        }
        return string
    }
}
