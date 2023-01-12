import Foundation
import Combine

class ResubscriptionService {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private var chatStorage: ChatStorage
    private var publishers = [AnyCancellable]()

    init(networkingInteractor: NetworkInteracting,
         chatStorage: ChatStorage,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.chatStorage = chatStorage
        setUpResubscription()
    }

    func setUpResubscription() {
        networkingInteractor.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                guard status == .connected else { return }

                Task(priority: .high) {
                    let topics = chatStorage.getThreads().map { $0.topic }
                    try await networkingInteractor.batchSubscribe(topics: topics)
                }
            }.store(in: &publishers)
    }
}
