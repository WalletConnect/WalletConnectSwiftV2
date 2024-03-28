import Foundation
import Combine

class LinkAuthRequestSubscriber {
    private let logger: ConsoleLogging
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let envelopesDispatcher: LinkEnvelopesDispatcher

    var onRequest: (((request: AuthenticationRequest, context: VerifyContext?)) -> Void)?

    init(
        logger: ConsoleLogging,
        kms: KeyManagementServiceProtocol,
        envelopesDispatcher: LinkEnvelopesDispatcher
    ) {
        self.logger = logger
        self.kms = kms
        self.envelopesDispatcher = envelopesDispatcher
        subscribeForRequest()
    }

    private func subscribeForRequest() {

        envelopesDispatcher.requestSubscription(on: SessionAuthenticatedProtocolMethod().method)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionAuthenticateRequestParams>) in

                logger.debug("LinkAuthRequestSubscriber: Received request")


                let request = AuthenticationRequest(id: payload.id, topic: payload.topic, payload: payload.request.authPayload, requester: payload.request.requester.metadata)


                // TODO fix verify context

                let verifyContext = VerifyContext(origin: "", validation: .valid)

                onRequest?((request, verifyContext))

            }.store(in: &publishers)

    }

}
