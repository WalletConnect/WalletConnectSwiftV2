import Foundation
import Combine
import WalletConnectNetworking

final class ResubscribeService {

    private var publishers = Set<AnyCancellable>()

    private let networkInteractor: NetworkInteracting
    private let pairingStorage: PairingStorage

    init(networkInteractor: NetworkInteracting, pairingStorage: PairingStorage) {
        self.networkInteractor = networkInteractor
        self.pairingStorage = pairingStorage
    }

    func resubscribe() {
        networkInteractor.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                pairingStorage.getAll()
                    .forEach { pairing in
                        Task(priority: .high) { try await networkInteractor.subscribe(topic: pairing.topic) }
                    }
            }
            .store(in: &publishers)
    }
}
