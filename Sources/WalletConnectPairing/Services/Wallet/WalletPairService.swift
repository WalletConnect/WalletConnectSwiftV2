import Foundation

actor WalletPairService {
    enum Errors: Error {
        case networkNotConnected
    }

    let networkingInteractor: NetworkInteracting
    let kms: KeyManagementServiceProtocol
    private let eventsClient: EventsClientProtocol
    private let pairingStorage: WCPairingStorage
    private let history: RPCHistory
    private let logger: ConsoleLogging

    init(
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        pairingStorage: WCPairingStorage,
        history: RPCHistory,
        logger: ConsoleLogging,
        eventsClient: EventsClientProtocol
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.pairingStorage = pairingStorage
        self.history = history
        self.logger = logger
        self.eventsClient = eventsClient
    }

    func pair(_ uri: WalletConnectURI) async throws {
        eventsClient.startTrace(topic: uri.topic)
        eventsClient.saveTraceEvent(PairingExecutionTraceEvents.pairingStarted)
        logger.debug("Pairing with uri: \(uri)")
        guard try !pairingHasPendingRequest(for: uri.topic) else {
            eventsClient.saveTraceEvent(PairingExecutionTraceEvents.pairingHasPendingRequest)
            logger.debug("Pairing with topic (\(uri.topic)) has pending request")
            return
        }
        if !networkingInteractor.isSocketConnected {
            eventsClient.saveTraceEvent(PairingExecutionTraceEvents.noWssConnection)
        }

        let pairing = WCPairing(uri: uri)
        let symKey = try SymmetricKey(hex: uri.symKey)
        try kms.setSymmetricKey(symKey, for: pairing.topic)
        pairingStorage.setPairing(pairing)
        eventsClient.saveTraceEvent(PairingExecutionTraceEvents.storeNewPairing)

        let networkConnectionStatus = await resolveNetworkConnectionStatus()
        guard networkConnectionStatus == .connected else {
            logger.debug("Pairing failed - Network is not connected")
            eventsClient.saveTraceEvent(PairingTraceErrorEvents.noInternetConnection)
            throw Errors.networkNotConnected
        }
        eventsClient.saveTraceEvent(PairingExecutionTraceEvents.subscribingPairingTopic)
        do {
            try await networkingInteractor.subscribe(topic: pairing.topic)
        } catch {
            logger.debug("Failed to subscribe to topic: \(pairing.topic)")
            eventsClient.saveTraceEvent(PairingTraceErrorEvents.subscribePairingTopicFailure)
            throw error
        }
    }
}

// MARK: - Private functions
extension WalletPairService {
    func pairingHasPendingRequest(for topic: String) throws -> Bool {
        guard let pairing = pairingStorage.getPairing(forTopic: topic), pairing.requestReceived else {
            return false
        }

        let pendingRequests = history.getPending()
            .compactMap { record -> RPCRequest? in
                (record.topic == pairing.topic) ? record.request : nil
            }

        guard !pendingRequests.isEmpty else { return false }
        pendingRequests.forEach { request in
            eventsClient.saveTraceEvent(PairingExecutionTraceEvents.emitSessionProposal)
            networkingInteractor.handleHistoryRequest(topic: topic, request: request)
        }
        return true
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
        case .networkNotConnected:              return "Pairing failed. You seem to be offline"
        }
    }
}
