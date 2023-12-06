import Foundation

class PairingDeleteRequester {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let pairingStorage: WCPairingStorage
    private let logger: ConsoleLogging

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         pairingStorage: WCPairingStorage,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.pairingStorage = pairingStorage
        self.logger = logger
    }

    func delete(topic: String) async throws {
        let reason = PairingReasonCode.userDisconnected
        let protocolMethod = PairingProtocolMethod.delete
        let pairingDeleteParams = PairingDeleteParams(code: reason.code, message: reason.message)
        logger.debug("Will delete pairing for reason: message: \(reason.message) code: \(reason.code)")
        let request = RPCRequest(method: protocolMethod.method, params: pairingDeleteParams)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)
        pairingStorage.delete(topic: topic)
        kms.deleteSymmetricKey(for: topic)
        networkingInteractor.unsubscribe(topic: topic)
    }
}
