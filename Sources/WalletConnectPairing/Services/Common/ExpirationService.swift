import Foundation
import Combine

final class ExpirationService {
    private let pairingStorage: WCPairingStorage
    private let networkInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let pairingExpirationPublisherSubject: PassthroughSubject<Pairing, Never> = .init()
    var pairingExpirationPublisher: AnyPublisher<Pairing, Never> {
        pairingExpirationPublisherSubject.eraseToAnyPublisher()
    }

    init(pairingStorage: WCPairingStorage, networkInteractor: NetworkInteracting, kms: KeyManagementServiceProtocol) {
        self.pairingStorage = pairingStorage
        self.networkInteractor = networkInteractor
        self.kms = kms
    }

    func setupExpirationHandling() {
        pairingStorage.onPairingExpiration = { [weak self] pairing in
            self?.kms.deleteSymmetricKey(for: pairing.topic)
            self?.networkInteractor.unsubscribe(topic: pairing.topic)

            DispatchQueue.main.async {
                self?.pairingExpirationPublisherSubject.send(Pairing(pairing))
            }
        }
    }
}
