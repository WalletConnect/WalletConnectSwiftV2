import Foundation
import Combine

class MessagingService {

    private let keyserverURL: URL
    private let networkingInteractor: NetworkInteracting
    private let identityClient: IdentityClient
    private let chatStorage: ChatStorage
    private let logger: ConsoleLogging

    private var publishers = [AnyCancellable]()

    init(
        keyserverURL: URL,
        networkingInteractor: NetworkInteracting,
        identityClient: IdentityClient,
        chatStorage: ChatStorage,
        logger: ConsoleLogging
    ) {
        self.keyserverURL = keyserverURL
        self.networkingInteractor = networkingInteractor
        self.identityClient = identityClient
        self.chatStorage = chatStorage
        self.logger = logger
        setUpResponseHandling()
        setUpRequestHandling()
    }

    func send(topic: String, messageString: String) async throws {
        guard let thread = chatStorage.getThread(topic: topic) else {
            throw Errors.threadDoNotExist
        }
        let payload = MessagePayload(keyserver: keyserverURL, message: messageString, recipientAccount: thread.peerAccount)
        let wrapper = try identityClient.signAndCreateWrapper(
            payload: payload,
            account: thread.selfAccount
        )

        let protocolMethod = ChatMessageProtocolMethod()
        let request = RPCRequest(method: protocolMethod.method, params: wrapper)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)

        logger.debug("Message sent on topic: \(topic)")
    }
}

private extension MessagingService {

    enum Errors: Error {
        case threadDoNotExist
    }

    func setUpResponseHandling() {
        networkingInteractor.responseSubscription(on: ChatMessageProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<MessagePayload.Wrapper, ReceiptPayload.Wrapper>) in

                logger.debug("Received Receipt response")

                guard
                    let (message, _) = try? MessagePayload.decodeAndVerify(from: payload.request),
                    let (receipt, _) = try? ReceiptPayload.decodeAndVerify(from: payload.response)
                else { fatalError() /* TODO: Handle error */ }

                let newMessage = Message(
                    topic: payload.topic,
                    message: message.message,
                    authorAccount: receipt.senderAccount,
                    timestamp: payload.publishedAt.millisecondsSince1970
                )

                chatStorage.set(message: newMessage, account: receipt.senderAccount)
            }.store(in: &publishers)
    }

    func setUpRequestHandling() {
        networkingInteractor.requestSubscription(on: ChatMessageProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<MessagePayload.Wrapper>) in

                logger.debug("Received Message Request")

                guard let (message, messageClaims) = try? MessagePayload.decodeAndVerify(from: payload.request)
                else { fatalError() /* TODO: Handle error */ }

                // TODO: Compare message hash

                Task(priority: .high) {

                    let authorAccount = try await identityClient.resolveIdentity(iss: messageClaims.iss)

                    let newMessage = Message(
                        topic: payload.topic,
                        message: message.message,
                        authorAccount: authorAccount,
                        timestamp: payload.publishedAt.millisecondsSince1970
                    )

                    chatStorage.set(message: newMessage, account: message.recipientAccount)

                    let messageHash = message.message
                        .data(using: .utf8)!
                        .sha256()
                        .toHexString()

                    let receiptPayload = ReceiptPayload(
                        keyserver: keyserverURL,
                        messageHash: messageHash,
                        senderAccount: authorAccount
                    )
                    let wrapper = try identityClient.signAndCreateWrapper(
                        payload: receiptPayload,
                        account: message.recipientAccount
                    )

                    let response = RPCResponse(id: payload.id, result: wrapper)

                    try await networkingInteractor.respond(
                        topic: payload.topic,
                        response: response,
                        protocolMethod: ChatMessageProtocolMethod()
                    )

                    logger.debug("Sent Receipt Response")
                }
            }.store(in: &publishers)
    }
}
