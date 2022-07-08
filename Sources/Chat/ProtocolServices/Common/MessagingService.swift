import Foundation
import WalletConnectUtils
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
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.messagesStore = messagesStore
        self.logger = logger
        setUpResponseHandling()
        setUpRequestHandling()
    }

    func send(topic: String, messageString: String) async throws {
        //TODO - manage author account
        let thread = await threadStore.first{$0.topic == topic}
        guard let authorAccount = thread?.selfAccount else { throw Errors.threadDoNotExist}
        let message = Message(topic: topic, message: messageString, authorAccount: authorAccount, timestamp: JsonRpcID.generate())
        let request = JSONRPCRequest<ChatRequestParams>(params: .message(message))
        try await networkingInteractor.request(request, topic: topic, envelopeType: .type0)
        Task(priority: .background) {
            await messagesStore.add(message)
        }
    }

    private func setUpResponseHandling() {
        networkingInteractor.responsePublisher
            .sink { [unowned self] response in
                switch response.requestParams {
                case .message:
                    handleMessageResponse(response)
                default:
                    return
                }
            }.store(in: &publishers)
    }

    private func setUpRequestHandling() {
        networkingInteractor.requestPublisher.sink { [unowned self] subscriptionPayload in
            switch subscriptionPayload.request.params {
            case .message(let message):
                handleMessage(message)
            default:
                return
            }
        }.store(in: &publishers)
    }

    private func handleMessage(_ message: Message) {
        Task(priority: .background) { await messagesStore.add(message) }
        logger.debug("Received message")
        onMessage?(message)
    }

    private func handleMessageResponse(_ response: ChatResponse) {
        logger.debug("Received Message response")
    }
}
