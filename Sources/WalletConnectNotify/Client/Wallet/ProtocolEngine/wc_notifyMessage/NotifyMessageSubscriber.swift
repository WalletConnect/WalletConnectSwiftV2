import Foundation
import Combine

class NotifyMessageSubscriber {
    private let keyserver: URL
    private let networkingInteractor: NetworkInteracting
    private let identityClient: IdentityClient
    private let notifyStorage: NotifyStorage
    private let crypto: CryptoProvider
    private let logger: ConsoleLogging
    private let notifyMessagePublisherSubject = PassthroughSubject<NotifyMessageRecord, Never>()

    public var notifyMessagePublisher: AnyPublisher<NotifyMessageRecord, Never> {
        notifyMessagePublisherSubject.eraseToAnyPublisher()
    }

    init(keyserver: URL, networkingInteractor: NetworkInteracting, identityClient: IdentityClient, notifyStorage: NotifyStorage, crypto: CryptoProvider, logger: ConsoleLogging) {
        self.keyserver = keyserver
        self.networkingInteractor = networkingInteractor
        self.identityClient = identityClient
        self.notifyStorage = notifyStorage
        self.crypto = crypto
        self.logger = logger
        subscribeForNotifyMessages()
    }

    private func subscribeForNotifyMessages() {
        networkingInteractor.subscribeOnRequest(
            protocolMethod: NotifyMessageProtocolMethod(),
            requestOfType: NotifyMessagePayload.Wrapper.self,
            errorHandler: logger
        ) { [unowned self] payload in
            logger.debug("Received Notify Message on topic: \(payload.topic)", properties: ["topic": payload.topic])

            let (messagePayload, claims) = try NotifyMessagePayload.decodeAndVerify(from: payload.request)

            logger.debug("Decoded Notify Message: \(payload.topic)", properties: ["topic": payload.topic, "messageBody": messagePayload.message.body, "messageTitle": messagePayload.message.title, "publishedAt": payload.publishedAt.description, "id": payload.id.string])

            let dappPubKey = try DIDKey(did: claims.iss)
            let record = NotifyMessageRecord(id: payload.id.string, topic: payload.topic, message: messagePayload.message, publishedAt: payload.publishedAt)
            notifyStorage.setMessage(record)
            notifyMessagePublisherSubject.send(record)

            let receiptPayload = NotifyMessageReceiptPayload(
                account: messagePayload.account,
                keyserver: keyserver,
                dappPubKey: dappPubKey,
                app: messagePayload.app
            )

            let wrapper = try identityClient.signAndCreateWrapper(
                payload: receiptPayload,
                account: messagePayload.account
            )

            let response = RPCResponse(id: payload.id, result: wrapper)

            try await networkingInteractor.respond(
                topic: payload.topic,
                response: response,
                protocolMethod: NotifyMessageProtocolMethod()
            )

            logger.debug("Sent Notify Message Response on topic: \(payload.topic)", properties: ["topic" : payload.topic, "messageBody": messagePayload.message.body, "messageTitle": messagePayload.message.title, "id": payload.id.string, "result": wrapper.jwtString])
        }
    }
}
