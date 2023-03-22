import Foundation
import Combine

final class ChatClientRequestSubscriber {

    private var publishers: Set<AnyCancellable> = []

    private let chatClient: ChatClient
    private let logger: ConsoleLogging

    var onRequest: ((RPCRequest) async throws -> Void)?

    init(chatClient: ChatClient, logger: ConsoleLogging) {
        self.chatClient = chatClient
        self.logger = logger

        setupSubscriptions()
    }

    func setupSubscriptions() {
        chatClient.newReceivedInvitePublisher
            .sink { [unowned self] invite in
                handle(event: .chatInvite, params: invite)
            }.store(in: &publishers)

        chatClient.newMessagePublisher
            .sink { [unowned self] message in
                handle(event: .chatMessage, params: message)
            }.store(in: &publishers)

        chatClient.acceptPublisher.sink { [unowned self] (topic, invite) in
            let params = AcceptPayload(topic: topic, invite: invite)
            handle(event: .chatInviteAccepted, params: params)
        }.store(in: &publishers)

        chatClient.rejectPublisher
            .sink { [unowned self] invite in
                handle(event: .chatInviteRejected, params: invite)
            }.store(in: &publishers)
    }
}

private extension ChatClientRequestSubscriber {

    struct AcceptPayload: Codable {
        let topic: String
        let invite: SentInvite
    }

    func handle(event: ChatClientRequest, params: Codable) {
        Task {
            do {
                let request = RPCRequest(
                    method: event.method,
                    params: params
                )
                try await onRequest?(request)
            } catch {
                logger.error("Client Request error: \(error.localizedDescription)")
            }
        }
    }
}
