import Foundation
import Combine

struct AuthResponseTopicRecord: Codable {
    let topic: String
    let expiry: Date

    var isExpired: Bool {
        expiry < Date()
    }

    init(topic: String, unixTimestamp: UInt64) {
        self.topic = topic
        self.expiry = Date(timeIntervalSince1970: TimeInterval(unixTimestamp))
    }
}

class AuthResponseTopicResubscriptionService {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()
    private let authResponseTopicRecordsStore: CodableStore<AuthResponseTopicRecord>

    init(
        networkingInteractor: NetworkInteracting,
        logger: ConsoleLogging,
        authResponseTopicRecordsStore: CodableStore<AuthResponseTopicRecord>
    ) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.authResponseTopicRecordsStore = authResponseTopicRecordsStore
        cleanExpiredRecordsIfNeeded()
        setupConnectionSubscriptions()
    }

    func setupConnectionSubscriptions() {
        networkingInteractor.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                guard status == .connected else { return }
                let topics = authResponseTopicRecordsStore.getAll().map{$0.topic}
                Task(priority: .high) {
                    try await networkingInteractor.batchSubscribe(topics: topics)
                }
            }
            .store(in: &publishers)
    }

    func cleanExpiredRecordsIfNeeded() {
        authResponseTopicRecordsStore.getAll().forEach { record in
            if record.isExpired {
                authResponseTopicRecordsStore.delete(forKey: record.topic)
            }
        }
    }
}
