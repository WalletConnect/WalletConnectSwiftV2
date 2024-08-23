import Foundation
import Combine

class LinkAuthRequestSubscriber {
    private let logger: ConsoleLogging
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let envelopesDispatcher: LinkEnvelopesDispatcher
    private let verifyClient: VerifyClientProtocol
    private let verifyContextStore: CodableStore<VerifyContext>
    private let eventsClient: EventsClientProtocol


    var onRequest: (((request: AuthenticationRequest, context: VerifyContext?)) -> Void)?

    init(
        logger: ConsoleLogging,
        kms: KeyManagementServiceProtocol,
        envelopesDispatcher: LinkEnvelopesDispatcher,
        verifyClient: VerifyClientProtocol,
        verifyContextStore: CodableStore<VerifyContext>,
        eventsClient: EventsClientProtocol
    ) {
        self.logger = logger
        self.kms = kms
        self.envelopesDispatcher = envelopesDispatcher
        self.verifyClient = verifyClient
        self.verifyContextStore = verifyContextStore
        self.eventsClient = eventsClient

        subscribeForRequest()
    }

    private func subscribeForRequest() {

        envelopesDispatcher
            .requestSubscription(on: SessionAuthenticatedProtocolMethod.responseApprove().method)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionAuthenticateRequestParams>) in

                Task(priority: .low) { eventsClient.saveMessageEvent(.sessionAuthenticateLinkModeReceived(payload.id)) }

                logger.debug("LinkAuthRequestSubscriber: Received request")


                let request = AuthenticationRequest(id: payload.id, topic: payload.topic, payload: payload.request.authPayload, requester: payload.request.requester.metadata)


                let metadata = payload.request.requester.metadata
                guard let redirect = metadata.redirect,
                let universalLink = redirect.universal else {
                    logger.warn("redirect property not present")
                    return
                }
                let verifyContext = verifyClient.createVerifyContextForLinkMode(redirectUniversalLink: universalLink, domain: metadata.url)
                verifyContextStore.set(verifyContext, forKey: request.id.string)

                onRequest?((request, verifyContext))

            }.store(in: &publishers)

    }

}
