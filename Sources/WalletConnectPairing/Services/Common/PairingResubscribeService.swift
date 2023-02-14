import Foundation
import Combine

final class PairingResubscribeService {

    private var publishers = Set<AnyCancellable>()

    private let networkInteractor: NetworkInteracting
    private let pairingStorage: PairingStorage

    init(networkInteractor: NetworkInteracting, pairingStorage: PairingStorage) {
        self.networkInteractor = networkInteractor
        self.pairingStorage = pairingStorage
        setUpResubscription()
    }

    func setUpResubscription() {
        networkInteractor.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                guard status == .connected else { return }
                let topics = pairingStorage.getAll().map{$0.topic}
                Task(priority: .high) {
                    try await networkInteractor.batchSubscribe(topics: topics)
                }
            }
            .store(in: &publishers)
    }
}
