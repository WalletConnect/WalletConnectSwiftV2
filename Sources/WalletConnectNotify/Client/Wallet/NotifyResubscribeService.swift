import Foundation
import Combine

final class NotifyResubscribeService {

    private var publishers = Set<AnyCancellable>()
    private let logger: ConsoleLogging

    private let networkInteractor: NetworkInteracting
    private let notifyStorage: NotifyStorage

    init(networkInteractor: NetworkInteracting, notifyStorage: NotifyStorage, logger: ConsoleLogging) {
        self.networkInteractor = networkInteractor
        self.notifyStorage = notifyStorage
        self.logger = logger
        setUpResubscription()
    }

    private func setUpResubscription() {
        networkInteractor.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                guard status == .connected else { return }
                let topics = notifyStorage.getAllSubscriptions().map { $0.topic }
                logger.debug("Resubscribing to notify subscription topics: \(topics)", properties: ["topics": topics.joined(separator: ", ")])
                Task(priority: .high) {
                    try await networkInteractor.batchSubscribe(topics: topics)
                }
            }
            .store(in: &publishers)
    }
}
