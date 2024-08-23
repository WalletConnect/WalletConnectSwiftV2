
import Foundation
import Combine

class LinkSessionRequestResponseSubscriber {
    private var publishers = [AnyCancellable]()
    private let envelopesDispatcher: LinkEnvelopesDispatcher
    private let eventsClient: EventsClientProtocol

    var onSessionResponse: ((Response) -> Void)?

    init(envelopesDispatcher: LinkEnvelopesDispatcher,
         eventsClient: EventsClientProtocol
    ) {
        self.envelopesDispatcher = envelopesDispatcher
        self.eventsClient = eventsClient
        setupRequestSubscription()
    }

    func setupRequestSubscription() {
        envelopesDispatcher.responseErrorSubscription(on: SessionRequestProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionErrorPayload<SessionType.RequestParams>) in
                Task(priority: .low) { eventsClient.saveMessageEvent(.sessionRequestLinkModeReceived(payload.id)) }
                onSessionResponse?(Response(
                    id: payload.id,
                    topic: payload.topic,
                    chainId: payload.request.chainId.absoluteString,
                    result: .error(payload.error)
                ))
            }
            .store(in: &publishers)

        envelopesDispatcher.responseSubscription(on: SessionRequestProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<SessionType.RequestParams, AnyCodable>) in
                Task(priority: .low) { eventsClient.saveMessageEvent(.sessionRequestLinkModeReceived(payload.id)) }
                Task(priority: .high) {
                    onSessionResponse?(Response(
                        id: payload.id,
                        topic: payload.topic,
                        chainId: payload.request.chainId.absoluteString,
                        result: .response(payload.response)
                    ))
                }
            }.store(in: &publishers)
    }
}
