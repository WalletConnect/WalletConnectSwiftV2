
import Foundation
import Combine

class NotifyProposeResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let metadata: AppMetadata
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    var proposalResponsePublisher: AnyPublisher<Result<PushSubscription, PushError>, Never> {
        proposalResponsePublisherSubject.eraseToAnyPublisher()
    }
    private let proposalResponsePublisherSubject = PassthroughSubject<Result<PushSubscription, PushError>, Never>()

    private var publishers = [AnyCancellable]()

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         metadata: AppMetadata) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.metadata = metadata
        subscribeForProposalResponse()
        subscribeForProposalErrors()
    }


    private func subscribeForProposalResponse() {
        let protocolMethod = NotifyProposeProtocolMethod()
        networkingInteractor.responseSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<NotifyProposeParams, NotifyProposeResponseParams>) in
                logger.debug("Received Notify Proposal response")
                Task(priority: .userInitiated) {
                    do {
                        let pushSubscription = try await handleResponse(payload: payload)
                        proposalResponsePublisherSubject.send(.success(pushSubscription))
                    } catch {
                        logger.error(error)
                    }
                }
            }.store(in: &publishers)
    }

    func handleResponse(payload: ResponseSubscriptionPayload<NotifyProposeParams, NotifyProposeResponseParams>) async throws -> PushSubscription {
        let jwtWrapper = SubscriptionJWTPayload.Wrapper(jwtString: payload.response.subscriptionAuth)
        let (_, claims) = try SubscriptionJWTPayload.decodeAndVerify(from: jwtWrapper)
        logger.debug("subscriptionAuth JWT validated")
        let expiry = Date(timeIntervalSince1970: TimeInterval(claims.exp))
        let subscriptionKey = try SymmetricKey(hex: payload.response.subscriptionSymKey)
        let subscriptionTopic = subscriptionKey.rawRepresentation.sha256().toHexString()
        let relay = RelayProtocolOptions(protocol: "irn", data: nil)
        let subscription = PushSubscription(topic: subscriptionTopic, account: payload.request.account, relay: relay, metadata: metadata, scope: [:], expiry: expiry)
        try kms.setSymmetricKey(subscriptionKey, for: subscriptionTopic)
        try await networkingInteractor.subscribe(topic: subscriptionTopic)
        return subscription
    }

    private func subscribeForProposalErrors() {
        let protocolMethod = NotifyProposeProtocolMethod()
        networkingInteractor.responseErrorSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: ResponseSubscriptionErrorPayload<NotifyProposeParams>) in
                kms.deletePrivateKey(for: payload.request.publicKey)
                networkingInteractor.unsubscribe(topic: payload.topic)
                guard let error = PushError(code: payload.error.code) else { return }
                proposalResponsePublisherSubject.send(.failure(error))
            }.store(in: &publishers)
    }

}
