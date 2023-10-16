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
    }

    func resubscribe(account: Account) async throws {
        let topics = notifyStorage.getSubscriptions(account: account).map { $0.topic }

        logger.debug(
            "Subscribed to notify subscription topics: \(topics)",
            properties: ["topics": topics.joined(separator: ", ")]
        )

        try await networkInteractor.batchSubscribe(topics: topics)
    }

    func unsubscribe(account: Account) async throws {
        let topics = notifyStorage.getSubscriptions(account: account).map { $0.topic }

        logger.debug(
            "Unsubscribed from notify subscription topics: \(topics)",
            properties: ["topics": topics.joined(separator: ", ")]
        )

        try await networkInteractor.batchUnsubscribe(topics: topics)
    }
}
