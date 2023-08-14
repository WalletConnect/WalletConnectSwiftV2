import Foundation

actor WalletPairService {
    enum Errors: Error {
        case pairingAlreadyExist(topic: String)
        case networkNotConnected
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
        
        let pairing = WCPairing(uri: uri)
        let symKey = try SymmetricKey(hex: uri.symKey)
        try kms.setSymmetricKey(symKey, for: pairing.topic)
        pairingStorage.setPairing(pairing)
        
        let networkConnectionStatus = await resolveNetworkConnectionStatus()
        guard networkConnectionStatus == .connected else {
            throw Errors.networkNotConnected
        }
        
        try await networkingInteractor.subscribe(topic: pairing.topic)
    }
}

// MARK: - Private functions
extension WalletPairService {
    func hasPairing(for topic: String) -> Bool {
        if let pairing = pairingStorage.getPairing(forTopic: topic) {
            return pairing.requestReceived
        }
        return false
    }
    
    private func resolveNetworkConnectionStatus() async -> NetworkConnectionStatus {
        return await withCheckedContinuation { continuation in
            let cancellable = networkingInteractor.networkConnectionStatusPublisher.sink { value in
                continuation.resume(returning: value)
            }
            
            Task(priority: .high) {
                await withTaskCancellationHandler {
                    cancellable.cancel()
                } onCancel: { }
            }
        }
    }
}

// MARK: - LocalizedError
extension WalletPairService.Errors: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .pairingAlreadyExist(let topic):   return "Pairing with topic (\(topic)) already exists. Use 'Web3Wallet.instance.getPendingProposals()' or 'Web3Wallet.instance.getPendingRequests()' in order to receive proposals or requests."
        case .networkNotConnected:              return "Pairing failed. You seem to be offline"
        }
    }
}
