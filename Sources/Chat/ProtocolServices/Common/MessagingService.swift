import Foundation
import Combine

class MessagingService {
    enum Errors: Error {
        case threadDoNotExist
    }
    let networkingInteractor: NetworkInteracting
    var messagesStore: Database<Message>
    let logger: ConsoleLogging
    var onMessage: ((Message) -> Void)?
    var threadStore: Database<Thread>
    private var publishers = [AnyCancellable]()

    init(networkingInteractor: NetworkInteracting,
         messagesStore: Database<Message>,
         threadStore: Database<Thread>,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.messagesStore = messagesStore
        self.logger = logger
        self.threadStore = threadStore
        setUpResponseHandling()
        setUpRequestHandling()
    }

    func send(topic: String, messageString: String) async throws {
        // TODO - manage author account
        let protocolMethod = ChatMessageProtocolMethod()
        let thread = await threadStore.first {$0.topic == topic}
        guard let authorAccount = thread?.selfAccount else { throw Errors.threadDoNotExist}
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let message = Message(topic: topic, message: messageString, authorAccount: authorAccount, timestamp: timestamp)
        let request = RPCRequest(method: protocolMethod.method, params: message)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)
        Task(priority: .background) {
            await messagesStore.add(message)
            onMessage?(message)
        }
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
        Task(priority: .background) {
            try await networkingInteractor.respondSuccess(topic: topic, requestId: requestId, protocolMethod: ChatMessageProtocolMethod())
            await messagesStore.add(message)
            logger.debug("Received message")
            onMessage?(message)
        }
    }
}
