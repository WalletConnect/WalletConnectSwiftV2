import Foundation
import Combine
import WalletConnectNetworking
import WalletConnectPairing
import WalletConnectEcho

public class WalletPushClient {

    private var publishers = Set<AnyCancellable>()

    private let requestPublisherSubject = PassthroughSubject<(id: RPCID, metadata: AppMetadata), Never>()

    public var requestPublisher: AnyPublisher<(id: RPCID, metadata: AppMetadata), Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }


    private let pushMessagePublisherSubject = PassthroughSubject<PushMessage, Never>()

    public var pushMessagePublisher: AnyPublisher<PushMessage, Never> {
        pushMessagePublisherSubject.eraseToAnyPublisher()
    }

    public let logger: ConsoleLogging

    private let pairingRegisterer: PairingRegisterer
    private let echoRegisterer: EchoClient
    private let proposeResponder: ProposeResponder
    private let pushMessageSubscriber: PushMessageSubscriber
    private let subscriptionsProvider: SubscriptionsProvider

    init(logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         echoRegisterer: EchoClient,
         pairingRegisterer: PairingRegisterer,
         proposeResponder: ProposeResponder,
         pushMessageSubscriber: PushMessageSubscriber,
         subscriptionsProvider: SubscriptionsProvider) {
        self.logger = logger
        self.pairingRegisterer = pairingRegisterer
        self.proposeResponder = proposeResponder
        self.echoRegisterer = echoRegisterer
        self.pushMessageSubscriber = pushMessageSubscriber
        self.subscriptionsProvider = subscriptionsProvider
        setupSubscriptions()
    }


    public func approve(id: RPCID) async throws {
        try await proposeResponder.respond(requestId: id)
    }

    public func reject(proposalId: String, reason: Reason) async throws {
        fatalError("not implemented")
    }

    public func getActiveSubscriptions() -> [PushSubscription] {
        subscriptionsProvider.getActiveSubscriptions()
    }

    public func delete(topic: String) async throws {
        fatalError("not implemented")
    }

    public func decryptMessage(topic: String, ciphertext: String) -> String {
        fatalError("not implemented")
    }


    public func register(deviceToken: Data) async throws {
        try await echoRegisterer.register(deviceToken: deviceToken)
    }
}

private extension WalletPushClient {

    func setupSubscriptions() {
        let protocolMethod = PushProposeProtocolMethod()

        pairingRegisterer.register(method: protocolMethod)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<PushRequestParams>) in
                requestPublisherSubject.send((id: payload.id, metadata: payload.request.metadata))
        }.store(in: &publishers)

        pushMessageSubscriber.onPushMessage = { [unowned self] pushMessage in
            pushMessagePublisherSubject.send(pushMessage)
        }
    }
}
