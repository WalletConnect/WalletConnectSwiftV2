import Foundation
import Combine

class MessagingService {

    private let keyserverURL: URL
    private let networkingInteractor: NetworkInteracting
    private let identityStorage: IdentityStorage
    private let identityService: IdentityService
    private let accountService: AccountService
    private let chatStorage: ChatStorage
    private let logger: ConsoleLogging

    private var publishers = [AnyCancellable]()

    private var currentAccount: Account {
        return accountService.currentAccount
    }

    init(
        keyserverURL: URL,
        networkingInteractor: NetworkInteracting,
        identityStorage: IdentityStorage,
        identityService: IdentityService,
        accountService: AccountService,
        chatStorage: ChatStorage,
        logger: ConsoleLogging
    ) {
        self.keyserverURL = keyserverURL
        self.networkingInteractor = networkingInteractor
        self.identityStorage = identityStorage
        self.identityService = identityService
        self.accountService = accountService
        self.chatStorage = chatStorage
        self.logger = logger
        setUpResponseHandling()
        setUpRequestHandling()
    }

    func send(topic: String, messageString: String) async throws {
        guard let thread = chatStorage.getThread(topic: topic, account: currentAccount) else {
            throw Errors.threadDoNotExist
        }

        let identityKey = try identityStorage.getIdentityKey(for: accountService.currentAccount)

        let payload = MessagePayload(keyserver: keyserverURL, message: messageString, recipientAccount: thread.peerAccount)
        let wrapper = try payload.signAndCreateWrapper(keyPair: identityKey)

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
                    let (message, messageClaims) = try? MessagePayload.decode(from: payload.request),
                    let (receipt, _) = try? ReceiptPayload.decode(from: payload.response)
                else { fatalError() /* TODO: Handle error */ }

                let newMessage = Message(
                    topic: payload.topic,
                    message: message.message,
                    authorAccount: receipt.senderAccount,
                    timestamp: messageClaims.iat // TODO: Replace with publishedAt
                )

                chatStorage.set(message: newMessage, account: receipt.senderAccount)
            }.store(in: &publishers)
    }

    func setUpRequestHandling() {
        networkingInteractor.requestSubscription(on: ChatMessageProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<MessagePayload.Wrapper>) in

                logger.debug("Received Message Request")

                guard let (message, messageClaims) = try? MessagePayload.decode(from: payload.request)
                else { fatalError() /* TODO: Handle error */ }

                Task(priority: .high) {

                    let authorAccount = try await identityService.resolveIdentity(iss: messageClaims.iss)

                    let newMessage = Message(
                        topic: payload.topic,
                        message: message.message,
                        authorAccount: authorAccount,
                        timestamp: messageClaims.iat // TODO: Replace with publishedAt
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

                    let identityKey = try identityStorage.getIdentityKey(for: accountService.currentAccount)

                    let wrapper = try receiptPayload.signAndCreateWrapper(keyPair: identityKey)
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
