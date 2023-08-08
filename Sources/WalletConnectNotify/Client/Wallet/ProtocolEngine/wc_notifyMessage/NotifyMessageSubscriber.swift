import Foundation
import Combine

class NotifyMessageSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let identityClient: IdentityClient
    private let notifyStorage: NotifyStorage
    private let crypto: CryptoProvider
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()
    private let notifyMessagePublisherSubject = PassthroughSubject<NotifyMessageRecord, Never>()

    public var notifyMessagePublisher: AnyPublisher<NotifyMessageRecord, Never> {
        notifyMessagePublisherSubject.eraseToAnyPublisher()
    }

    init(networkingInteractor: NetworkInteracting, identityClient: IdentityClient, notifyStorage: NotifyStorage, crypto: CryptoProvider, logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.identityClient = identityClient
        self.notifyStorage = notifyStorage
        self.crypto = crypto
        self.logger = logger
        subscribeForNotifyMessages()
    }

    private func subscribeForNotifyMessages() {
        let protocolMethod = NotifyMessageProtocolMethod()
        networkingInteractor.requestSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<NotifyMessagePayload.Wrapper>) in

                logger.debug("Received Notify Message")

                Task(priority: .high) {
                    do {
                        let (messagePayload, claims) = try NotifyMessagePayload.decodeAndVerify(from: payload.request)
                        let dappIdentityKey = try DIDKey(did: claims.iss)
                        let messageData = try JSONEncoder().encode(messagePayload.message)

                        let record = NotifyMessageRecord(id: payload.id.string, topic: payload.topic, message: messagePayload.message, publishedAt: payload.publishedAt)
                        notifyStorage.setMessage(record)
                        notifyMessagePublisherSubject.send(record)

                        let receiptPayload = NotifyMessageReceiptPayload(
                            dappIdentityKey: dappIdentityKey,
                            messageHash: crypto.keccak256(messageData).toHexString(),
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

                        logger.debug("Sent Notify Receipt Response")
                    } catch {
                        fatalError() /* TODO: Handle error */
                    }
                }

            }.store(in: &publishers)

    }
}
