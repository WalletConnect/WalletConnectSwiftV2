import Foundation
import Combine

class MessagingService {
    enum Errors: Error {
        case threadDoNotExist
    }

    var onMessage: ((Message) -> Void)?

    private let networkingInteractor: NetworkInteracting
    private let accountService: AccountService
    private let chatStorage: ChatStorage
    private let logger: ConsoleLogging

    private var publishers = [AnyCancellable]()

    private var currentAccount: Account {
        return accountService.currentAccount
    }

    init(networkingInteractor: NetworkInteracting,
         accountService: AccountService,
         chatStorage: ChatStorage,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.accountService = accountService
        self.chatStorage = chatStorage
        self.logger = logger
        setUpResponseHandling()
        setUpRequestHandling()
    }

    func send(topic: String, messageString: String) async throws {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let message = Message(topic: topic, message: messageString, authorAccount: currentAccount, timestamp: timestamp)

        let protocolMethod = ChatMessageProtocolMethod()
        let request = RPCRequest(method: protocolMethod.method, params: message)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)

        chatStorage.set(message: message, account: currentAccount)
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
            .sink { [unowned self] (payload: RequestSubscriptionPayload<MessagePayload>) in
                let message = Message(topic: payload.topic, payload: payload.request)
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
            chatStorage.set(message: message, account: currentAccount)
            onMessage?(message)
        }
    }
}
