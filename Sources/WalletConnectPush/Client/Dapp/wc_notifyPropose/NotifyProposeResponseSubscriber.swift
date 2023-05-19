
import Foundation
import Combine

class NotifyProposeResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    var onResponse: ((_ id: RPCID, _ result: Result<PushSubscription, PushError>) -> Void)?
    private var publishers = [AnyCancellable]()

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
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
                        onResponse?(payload.id, .success(result))
                    } catch {
                        logger.error(error)
                    }
                }
            }.store(in: &publishers)
    }


    func handleResponse(payload: ResponseSubscriptionPayload<NotifyProposeParams, SubscriptionJWTPayload.Wrapper>) async throws -> PushSubscription {
        let jwt = payload.response.jwtString
        let (_, claims) = try SubscriptionJWTPayload.decodeAndVerify(from: payload.response)
        logger.debug("subscriptionAuth JWT validated")

        let expiry = Date(timeIntervalSince1970: TimeInterval(claims.exp))

        let updateTopic = jwt.data(using: .utf8)?.sha256().hexString


        Subscription should have reference to update topic
        let pushSubscription = PushSubscription(topic: subscriptionTopic, account: payload.request.account, relay: relay, metadata: metadata, scope: [:], expiry: expiry)

    }


}
