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
        chatClient.invitePublisher
            .sink { [unowned self] invite in
                handle(event: .chatInvite, params: invite)
            }.store(in: &publishers)

        chatClient.newThreadPublisher
            .sink { [unowned self] thread in
                handle(event: .chatThread, params: thread)
            }.store(in: &publishers)

        chatClient.messagePublisher
            .sink { [unowned self] message in
                handle(event: .chatMessage, params: message)
            }.store(in: &publishers)
    }
}

private extension ChatClientRequestSubscriber {

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
