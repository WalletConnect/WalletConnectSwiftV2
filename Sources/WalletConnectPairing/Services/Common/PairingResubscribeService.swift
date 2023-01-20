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
                pairingStorage.getAll()
                    .forEach { pairing in
                        Task(priority: .high) { try await networkInteractor.subscribe(topic: pairing.topic) }
                    }
            }
            .store(in: &publishers)
    }
}
