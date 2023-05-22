
import Foundation
import Combine

class NotifyProposeResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let metadata: AppMetadata
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    var proposalResponsePublisher: AnyPublisher<Result<PushSubscription, Error>, Never> {
        proposalResponsePublisherSubject.eraseToAnyPublisher()
    }
    private let proposalResponsePublisherSubject = PassthroughSubject<Result<PushSubscription, Error>, Never>()

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
    }


    private func subscribeForProposalResponse() {
        let protocolMethod = NotifyProposeProtocolMethod()
        networkingInteractor.responseSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<NotifyProposeParams, SubscriptionJWTPayload.Wrapper>) in
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

    /// Implemented only for integration testing purpose, dapp client is not supported
    func handleResponse(payload: ResponseSubscriptionPayload<NotifyProposeParams, SubscriptionJWTPayload.Wrapper>) async throws -> PushSubscription {
        let (_, claims) = try SubscriptionJWTPayload.decodeAndVerify(from: payload.response)
        logger.debug("subscriptionAuth JWT validated")

        let expiry = Date(timeIntervalSince1970: TimeInterval(claims.exp))

        let updateTopic = "update_topic"

        let relay = RelayProtocolOptions(protocol: "irn", data: nil)

        return PushSubscription(topic: updateTopic, account: payload.request.account, relay: relay, metadata: metadata, scope: [:], expiry: expiry)
    }


}
