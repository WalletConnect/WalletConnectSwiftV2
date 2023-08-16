import Foundation

actor WalletPairService {
    enum Errors: Error {
        case pairingAlreadyExist(topic: String)
        case networkNotConnected
    }

    let networkingInteractor: NetworkInteracting
    let kms: KeyManagementServiceProtocol
    private let pairingStorage: WCPairingStorage
    private let history: RPCHistory

    init(
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        pairingStorage: WCPairingStorage,
        history: RPCHistory
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.pairingStorage = pairingStorage
        self.history = history
    }

    func pair(_ uri: WalletConnectURI) async throws {
        guard try !pairingHasPendingRequest(for: uri.topic) else {
            return
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
    func pairingHasPendingRequest(for topic: String) throws -> Bool {
        guard let pairing = pairingStorage.getPairing(forTopic: topic), pairing.requestReceived else {
            return false
        }
        
        if pairing.active {
            throw Errors.pairingAlreadyExist(topic: topic)
        }
        
        let pendingRequests = history.getPending()
            .compactMap { record -> RPCRequest? in
                (record.topic == pairing.topic) ? record.request : nil
            }

        if let pendingRequest = pendingRequests.first {
            networkingInteractor.handleHistoryRequest(topic: topic, request: pendingRequest)
            return true
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
        case .pairingAlreadyExist(let topic):   return "Pairing with topic (\(topic)) is already active"
        case .networkNotConnected:              return "Pairing failed. You seem to be offline"
        }
    }
}
