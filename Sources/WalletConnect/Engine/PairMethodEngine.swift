
import Foundation
import WalletConnectKMS

actor PairMethodEngine {
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
        print("trying")
        guard !hasPairing(for: uri.topic) else {
            throw WalletConnectError.pairingAlreadyExist
        }
        var pairing = WCPairing(uri: uri)
        print("Pairing")
        try await networkingInteractor.subscribeA(topic: pairing.topic)
        print("SUBSCRIBED")
        let symKey = try! SymmetricKey(hex: uri.symKey) // FIXME: Malformed QR code from external source can crash the SDK
        try! kms.setSymmetricKey(symKey, for: pairing.topic)
        pairing.activate()
        pairingStore.setPairing(pairing)
    }
    
    func hasPairing(for topic: String) -> Bool {
        return pairingStore.hasPairing(forTopic: topic)
    }
}
