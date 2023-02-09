import Foundation
import Combine
import WalletConnectNetworking
import WalletConnectPairing
import WalletConnectEcho


public class WalletPushClient {

    private var publishers = Set<AnyCancellable>()

    public var subscriptionsPublisher: AnyPublisher<[PushSubscription], Never> {
        return pushSubscriptionsObserver.subscriptionsPublisher
    }

    private let pushSubscriptionsObserver: PushSubscriptionsObserver

    private let requestPublisherSubject = PassthroughSubject<PushRequest, Never>()

    public var requestPublisher: AnyPublisher<PushRequest, Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    private let pushMessagePublisherSubject = PassthroughSubject<PushMessageRecord, Never>()

    public var pushMessagePublisher: AnyPublisher<PushMessageRecord, Never> {
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
    private let pushMessagesDatabase: PushMessagesDatabase
    private let resubscribeService: PushResubscribeService

    init(logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         echoClient: EchoClient,
         pairingRegisterer: PairingRegisterer,
         proposeResponder: PushRequestResponder,
         pushMessageSubscriber: PushMessageSubscriber,
         subscriptionsProvider: SubscriptionsProvider,
         pushMessagesDatabase: PushMessagesDatabase,
         deletePushSubscriptionService: DeletePushSubscriptionService,
         deletePushSubscriptionSubscriber: DeletePushSubscriptionSubscriber,
         resubscribeService: PushResubscribeService,
         pushSubscriptionsObserver: PushSubscriptionsObserver) {
        self.logger = logger
        self.pairingRegisterer = pairingRegisterer
        self.proposeResponder = proposeResponder
        self.echoClient = echoClient
        self.pushMessageSubscriber = pushMessageSubscriber
        self.subscriptionsProvider = subscriptionsProvider
        self.pushMessagesDatabase = pushMessagesDatabase
        self.deletePushSubscriptionService = deletePushSubscriptionService
        self.deletePushSubscriptionSubscriber = deletePushSubscriptionSubscriber
        self.resubscribeService = resubscribeService
        self.pushSubscriptionsObserver = pushSubscriptionsObserver
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

    public func getMessageHistory(topic: String) -> [PushMessageRecord] {
        pushMessagesDatabase.getPushMessages(topic: topic)
    }

    public func deleteSubscription(topic: String) async throws {
        try await deletePushSubscriptionService.delete(topic: topic)
    }

    public func deletePushMessage(id: String) {
        pushMessagesDatabase.deletePushMessage(id: id)
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

        pushMessageSubscriber.onPushMessage = { [unowned self] pushMessageRecord in
            pushMessagePublisherSubject.send(pushMessageRecord)
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

