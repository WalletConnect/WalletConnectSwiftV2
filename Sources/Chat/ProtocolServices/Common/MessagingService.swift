import Foundation
import Combine

class MessagingService {
    enum Errors: Error {
        case threadDoNotExist
    }

    var onMessage: ((Message) -> Void)?

    private let networkingInteractor: NetworkInteracting
    private let chatStorage: ChatStorage
    private let logger: ConsoleLogging

    private var publishers = [AnyCancellable]()

    init(networkingInteractor: NetworkInteracting,
         chatStorage: ChatStorage,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.chatStorage = chatStorage
        self.logger = logger
        setUpResponseHandling()
        setUpRequestHandling()
    }

    func send(topic: String, messageString: String) async throws {
        // TODO - manage author account

        guard let authorAccount = chatStorage.getThread(topic: topic)?.selfAccount
        else { throw Errors.threadDoNotExist}

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let message = Message(topic: topic, message: messageString, authorAccount: authorAccount, timestamp: timestamp)

        let protocolMethod = ChatMessageProtocolMethod()
        let request = RPCRequest(method: protocolMethod.method, params: message)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)

        onMessage?(message)
    }

    private func setUpResponseHandling() {
        networkingInteractor.responseSubscription(on: ChatMessageProtocolMethod())
            .sink { [unowned self] (_: ResponseSubscriptionPayload<AnyCodable, AnyCodable>) in
                logger.debug("Received Message response")
            }.store(in: &publishers)
    }

    private func setUpRequestHandling() {
        networkingInteractor.requestSubscription(on: ChatMessageProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<Message>) in
                var message = payload.request
                message.topic = payload.topic
                handleMessage(message, topic: payload.topic, requestId: payload.id)
            }.store(in: &publishers)
    }

    private func handleMessage(_ message: Message, topic: String, requestId: RPCID) {
        Task(priority: .high) {
            try await networkingInteractor.respondSuccess(
                topic: topic,
                requestId: requestId,
                protocolMethod: ChatMessageProtocolMethod()
            )
            logger.debug("Received message")
            onMessage?(message)
        }
    }
}
