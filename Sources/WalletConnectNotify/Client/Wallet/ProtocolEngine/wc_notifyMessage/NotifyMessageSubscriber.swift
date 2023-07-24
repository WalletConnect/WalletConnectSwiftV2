import Foundation
import Combine

class NotifyMessageSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let notifyStorage: NotifyStorage
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()
    private let notifyMessagePublisherSubject = PassthroughSubject<NotifyMessageRecord, Never>()

    public var notifyMessagePublisher: AnyPublisher<NotifyMessageRecord, Never> {
        notifyMessagePublisherSubject.eraseToAnyPublisher()
    }

    init(networkingInteractor: NetworkInteracting, notifyStorage: NotifyStorage, logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.notifyStorage = notifyStorage
        self.logger = logger
        subscribeForNotifyMessages()
    }

    private func subscribeForNotifyMessages() {
        let protocolMethod = NotifyMessageProtocolMethod()
        networkingInteractor.requestSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<NotifyMessage>) in
                logger.debug("Received Notify Message")

                let record = NotifyMessageRecord(id: payload.id.string, topic: payload.topic, message: payload.request, publishedAt: payload.publishedAt)
                notifyStorage.setMessage(record)
                notifyMessagePublisherSubject.send(record)

            }.store(in: &publishers)

    }
}
