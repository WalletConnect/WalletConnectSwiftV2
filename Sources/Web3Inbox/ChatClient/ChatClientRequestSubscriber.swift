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
                Task { @MainActor in
                    do {
                        let request = RPCRequest(
                            method: ChatClientRequest.chatInvite.method,
                            params: invite
                        )
                        try await onRequest?(request)
                    } catch {
                        logger.error("Client Request error: \(error.localizedDescription)")
                    }
                }
            }.store(in: &publishers)
    }
}
