import Foundation

actor WalletPairService {
    enum Errors: Error {
        case pairingAlreadyExist(topic: String)
    }

    let networkingInteractor: NetworkInteracting
    let kms: KeyManagementServiceProtocol
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
            throw Errors.pairingAlreadyExist(topic: uri.topic)
        }
        var pairing = WCPairing(uri: uri)
        let symKey = try SymmetricKey(hex: uri.symKey)
        try kms.setSymmetricKey(symKey, for: pairing.topic)
        pairing.activate()
        pairingStorage.setPairing(pairing)
        try await networkingInteractor.subscribe(topic: pairing.topic)
    }

    func hasPairing(for topic: String) -> Bool {
        return pairingStorage.hasPairing(forTopic: topic)
    }
}

// MARK: - LocalizedError
extension WalletPairService.Errors: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .pairingAlreadyExist(let topic):   return "Pairing with topic (\(topic)) already exist"
        }
    }
}
