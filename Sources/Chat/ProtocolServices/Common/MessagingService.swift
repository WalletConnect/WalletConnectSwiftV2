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
        let jwt = try makeMessageJWT(recipientAccount: thread.peerAccount, message: messageString)
        let payload = MessagePayload(messageAuth: jwt)
        let protocolMethod = ChatMessageProtocolMethod()
        let request = RPCRequest(method: protocolMethod.method, params: payload)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)

        logger.debug("Message sent on topic: \(topic)")
    }
}

private extension MessagingService {

    enum Errors: Error {
        case threadDoNotExist
        case identityKeyNotFound
    }

    func setUpResponseHandling() {
        networkingInteractor.responseSubscription(on: ChatMessageProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<MessagePayload, ReceiptPayload>) in

                logger.debug("Received Receipt response")

                guard
                    let messagePayload = try? payload.request.decode(),
                    let receiptPayload = try? payload.response.decode()
                else { fatalError() /* TODO: Handle error */ }

                let message = Message(
                    topic: payload.topic,
                    message: messagePayload.message,
                    authorAccount: receiptPayload.senderAccount,
                    timestamp: messagePayload.timestamp
                )

                chatStorage.set(message: message, account: receiptPayload.senderAccount)
            }.store(in: &publishers)
    }

    func setUpRequestHandling() {
        networkingInteractor.requestSubscription(on: ChatMessageProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<MessagePayload>) in

                logger.debug("Received Message Request")

                guard let decoded = try? payload.request.decode()
                else { fatalError() /* TODO: Handle error */ }

                Task(priority: .high) {

                    let authorAccount = try await identityService.resolveIdentity(iss: decoded.iss)

                    let message = Message(
                        topic: payload.topic,
                        message: decoded.message,
                        authorAccount: authorAccount,
                        timestamp: decoded.timestamp
                    )

                    chatStorage.set(message: message, account: decoded.recipientAccount)

                    let messageHash = message.message
                        .data(using: .utf8)!
                        .sha256()
                        .toHexString()

                    let jwt = try makeReceiptJWT(senderAccount: authorAccount, messageHash: messageHash)
                    let params = ReceiptPayload(receiptAuth: jwt)
                    let response = RPCResponse(id: payload.id, result: params)

                    try await networkingInteractor.respond(
                        topic: payload.topic,
                        response: response,
                        protocolMethod: ChatMessageProtocolMethod()
                    )

                    logger.debug("Sent Receipt Response")
                }
            }.store(in: &publishers)
    }

    func makeMessageJWT(recipientAccount: Account, message: String) throws -> String {
        guard let identityKey = identityStorage.getIdentityKey(for: accountService.currentAccount)
        else { throw Errors.identityKeyNotFound }

        return try JWTFactory(keyPair: identityKey).createChatMessageJWT(
            ksu: keyserverURL.absoluteString,
            aud: DIDPKH(account: recipientAccount).string,
            sub: message
        )
    }

    func makeReceiptJWT(senderAccount: Account, messageHash: String) throws -> String {
        guard let identityKey = identityStorage.getIdentityKey(for: accountService.currentAccount)
        else { throw Errors.identityKeyNotFound }

        return try JWTFactory(keyPair: identityKey).createChatMessageJWT(
            ksu: keyserverURL.absoluteString,
            aud: DIDPKH(account: senderAccount).string,
            sub: messageHash
        )
    }
}
