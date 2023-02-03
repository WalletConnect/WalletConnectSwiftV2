import Foundation
import Combine
import WalletConnectNetworking
import WalletConnectPairing
import WalletConnectEcho


public class WalletPushClient {

    private var publishers = Set<AnyCancellable>()

    private let requestPublisherSubject = PassthroughSubject<PushRequest, Never>()

    public var requestPublisher: AnyPublisher<PushRequest, Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    private let pushMessagePublisherSubject = PassthroughSubject<PushMessage, Never>()

    public var pushMessagePublisher: AnyPublisher<PushMessage, Never> {
        pushMessagePublisherSubject.eraseToAnyPublisher()
    }

    private let deleteSubscriptionPublisherSubject = PassthroughSubject<String, Never>()

    public var deleteSubscriptionPublisher: AnyPublisher<String, Never> {
        deleteSubscriptionPublisherSubject.eraseToAnyPublisher()
    }

    private let deletePushSubscriptionService: DeletePushSubscriptionService
    private let deletePushSubscriptionSubscriber: DeletePushSubscriptionSubscriber

    public let logger: ConsoleLogging

    private let pairingRegisterer: PairingRegisterer
    private let echoClient: EchoClient
    private let proposeResponder: PushRequestResponder
    private let pushMessageSubscriber: PushMessageSubscriber
    private let subscriptionsProvider: SubscriptionsProvider
    private let pushMessagesProvider: PushMessagesProvider
    private let resubscribeService: PushResubscribeService

    init(logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         echoClient: EchoClient,
         pairingRegisterer: PairingRegisterer,
         proposeResponder: PushRequestResponder,
         pushMessageSubscriber: PushMessageSubscriber,
         subscriptionsProvider: SubscriptionsProvider,
         pushMessagesProvider: PushMessagesProvider,
         deletePushSubscriptionService: DeletePushSubscriptionService,
         deletePushSubscriptionSubscriber: DeletePushSubscriptionSubscriber,
         resubscribeService: PushResubscribeService) {
        self.logger = logger
        self.pairingRegisterer = pairingRegisterer
        self.proposeResponder = proposeResponder
        self.echoClient = echoClient
        self.pushMessageSubscriber = pushMessageSubscriber
        self.subscriptionsProvider = subscriptionsProvider
        self.pushMessagesProvider = pushMessagesProvider
        self.deletePushSubscriptionService = deletePushSubscriptionService
        self.deletePushSubscriptionSubscriber = deletePushSubscriptionSubscriber
        self.resubscribeService = resubscribeService
        setupSubscriptions()
    }

    public func approve(id: RPCID) async throws {
        try await proposeResponder.respond(requestId: id)
    }

    public func reject(id: RPCID) async throws {
        try await proposeResponder.respondError(requestId: id)
    }

    public func getActiveSubscriptions() -> [PushSubscription] {
        subscriptionsProvider.getActiveSubscriptions()
    }

    public func getMessageHistory(topic: String) -> [PushMessage] {
        pushMessagesProvider.getMessageHistory(topic: topic)
    }

    public func delete(topic: String) async throws {
        try await deletePushSubscriptionService.delete(topic: topic)
    }

    public func register(deviceToken: Data) async throws {
        try await echoClient.register(deviceToken: deviceToken)
    }
}

private extension WalletPushClient {

    func setupSubscriptions() {
        let protocolMethod = PushRequestProtocolMethod()

        pairingRegisterer.register(method: protocolMethod)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<PushRequestParams>) in
                requestPublisherSubject.send((id: payload.id, account: payload.request.account, metadata: payload.request.metadata))
        }.store(in: &publishers)

        pushMessageSubscriber.onPushMessage = { [unowned self] pushMessage in
            pushMessagePublisherSubject.send(pushMessage)
        }
        deletePushSubscriptionSubscriber.onDelete = {[unowned self] topic in
            deleteSubscriptionPublisherSubject.send(topic)
        }
    }
}

#if targetEnvironment(simulator)
extension WalletPushClient {
    public func register(deviceToken: String) async throws {
        try await echoClient.register(deviceToken: deviceToken)
    }
}
#endif
