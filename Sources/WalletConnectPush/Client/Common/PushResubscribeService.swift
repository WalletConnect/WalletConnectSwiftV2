import Foundation
import Combine

final class PushResubscribeService {

    private var publishers = Set<AnyCancellable>()

    private let networkInteractor: NetworkInteracting
    private let pushStorage: PushStorage

    init(networkInteractor: NetworkInteracting, pushStorage: PushStorage) {
        self.networkInteractor = networkInteractor
        self.pushStorage = pushStorage
        setUpResubscription()
    }

    func setUpResubscription() {
        networkInteractor.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                guard status == .connected else { return }
                let topics = pushStorage.getSubscriptions().map{$0.topic}
                Task(priority: .high) {
                    try await networkInteractor.batchSubscribe(topics: topics)
                }
            }
            .store(in: &publishers)
    }
}
