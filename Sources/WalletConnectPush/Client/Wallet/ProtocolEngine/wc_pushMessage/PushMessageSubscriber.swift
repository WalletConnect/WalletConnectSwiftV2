import Foundation
import Combine

class PushMessageSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let pushStorage: PushStorage
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()
    private let pushMessagePublisherSubject = PassthroughSubject<PushMessageRecord, Never>()

    public var pushMessagePublisher: AnyPublisher<PushMessageRecord, Never> {
        pushMessagePublisherSubject.eraseToAnyPublisher()
    }

    init(networkingInteractor: NetworkInteracting, pushStorage: PushStorage, logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.pushStorage = pushStorage
        self.logger = logger
        subscribeForPushMessages()
    }

    private func subscribeForPushMessages() {
        let protocolMethod = PushMessageProtocolMethod()
        networkingInteractor.requestSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<PushMessage>) in
                logger.debug("Received Push Message")

                let record = PushMessageRecord(id: payload.id.string, topic: payload.topic, message: payload.request, publishedAt: payload.publishedAt)
                pushStorage.setMessage(record)
                pushMessagePublisherSubject.send(record)

            }.store(in: &publishers)

    }
}
