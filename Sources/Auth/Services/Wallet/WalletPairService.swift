import Foundation
import WalletConnectKMS
import WalletConnectPairing

actor WalletPairService {
    enum Errors: Error {
        case pairingAlreadyExist
    }

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let pairingStorage: WCPairingStorage

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         pairingStorage: WCPairingStorage) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.pairingStorage = pairingStorage
    }

    func pair(_ uri: WalletConnectURI) async throws {
        guard !hasPairing(for: uri.topic) else {
            throw Errors.pairingAlreadyExist
        }
        var pairing = WCPairing(uri: uri)
        try await networkingInteractor.subscribe(topic: pairing.topic)
        let symKey = try SymmetricKey(hex: uri.symKey)
        try kms.setSymmetricKey(symKey, for: pairing.topic)
        pairing.activate()
        pairingStorage.setPairing(pairing)
    }

    func hasPairing(for topic: String) -> Bool {
        return pairingStorage.hasPairing(forTopic: topic)
    }
}
