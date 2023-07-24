import Foundation
import Combine

final class NotifyResubscribeService {

    private var publishers = Set<AnyCancellable>()

    private let networkInteractor: NetworkInteracting
    private let notifyStorage: NotifyStorage

    init(networkInteractor: NetworkInteracting, notifyStorage: NotifyStorage) {
        self.networkInteractor = networkInteractor
        self.notifyStorage = notifyStorage
        setUpResubscription()
    }

    func setUpResubscription() {
        networkInteractor.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                guard status == .connected else { return }
                let topics = notifyStorage.getSubscriptions().map{$0.topic}
                Task(priority: .high) {
                    try await networkInteractor.batchSubscribe(topics: topics)
                }
            }
            .store(in: &publishers)
    }
}
