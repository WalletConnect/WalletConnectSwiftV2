import Foundation
import WalletConnectNetworking
import WalletConnectKMS

final class ExpirationService {
    private let pairingStorage: PairingStorage
    private let networkInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol

    init(pairingStorage: PairingStorage, networkInteractor: NetworkInteracting, kms: KeyManagementServiceProtocol) {
        self.pairingStorage = pairingStorage
        self.networkInteractor = networkInteractor
        self.kms = kms
    }

    func setupExpirationHandling() {
        pairingStorage.onPairingExpiration = { [weak self] pairing in
            self?.kms.deleteSymmetricKey(for: pairing.topic)
            self?.networkInteractor.unsubscribe(topic: pairing.topic)
        }
    }
}
