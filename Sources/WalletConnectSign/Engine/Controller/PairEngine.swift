import Foundation
import WalletConnectKMS
import WalletConnectPairing

actor PairEngine {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let pairingStore: WCPairingStorage

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         pairingStore: WCPairingStorage) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.pairingStore = pairingStore
    }

    func pair(_ uri: WalletConnectURI) async throws {
        guard !hasPairing(for: uri.topic) else {
            throw WalletConnectError.pairingAlreadyExist
        }
        var pairing = WCPairing(uri: uri)
        try await networkingInteractor.subscribe(topic: pairing.topic)
        let symKey = try SymmetricKey(hex: uri.symKey)
        try kms.setSymmetricKey(symKey, for: pairing.topic)
        pairing.activate()
        pairingStore.setPairing(pairing)
    }

    func hasPairing(for topic: String) -> Bool {
        return pairingStore.hasPairing(forTopic: topic)
    }
}
