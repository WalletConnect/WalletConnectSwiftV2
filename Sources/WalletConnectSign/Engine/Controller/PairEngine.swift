import Foundation
import WalletConnectKMS

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
        
        try await subscribe(to: uri.topic)
        try await setSymmetricKey(uri.symKey, topic: pairing.topic)

        pairing.activate()
        pairingStore.setPairing(pairing)
    }
    
    private func setSymmetricKey(_ uriSymKey: String, topic: String) async throws {
        do {
            let symKey = try SymmetricKey(hex: uriSymKey)
            try kms.setSymmetricKey(symKey, for: topic)
        } catch {
            throw WalletConnectError.malformedPairingURI
        }
    }
    
    private func subscribe(to topic: String) async throws {
        do {
            try await networkingInteractor.subscribe(topic: topic)
        } catch {
            throw WalletConnectError.noPairingMatchingTopic(topic)
        }
    }
    
    func hasPairing(for topic: String) -> Bool {
        return pairingStore.hasPairing(forTopic: topic)
    }
}
