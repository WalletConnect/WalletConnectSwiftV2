import Foundation
import Combine

class ResubscriptionService {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private var threadStore: Database<Thread>
    private var publishers = [AnyCancellable]()

    init(networkingInteractor: NetworkInteracting,
         threadStore: Database<Thread>,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.threadStore = threadStore
        setUpResubscription()
    }

    func setUpResubscription() {
        networkingInteractor.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                guard status == .connected else { return }
                Task(priority: .background) {
                    let topics = await threadStore.getAll().map {$0.topic}
                    topics.forEach { topic in Task(priority: .background) { try? await networkingInteractor.subscribe(topic: topic) } }
                }
            }.store(in: &publishers)
    }
}
