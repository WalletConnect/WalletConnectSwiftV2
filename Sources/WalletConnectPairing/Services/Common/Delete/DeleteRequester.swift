import Foundation

public final class DeleteRequester {
    private let method: ProtocolMethod
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let pairingStorage: WCPairingStorage
    private let logger: ConsoleLogging

    public init(
        networkingInteractor: NetworkInteracting,
        method: ProtocolMethod,
        kms: KeyManagementServiceProtocol,
        pairingStorage: WCPairingStorage,
        logger: ConsoleLogging
    ) {
        self.method = method
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.pairingStorage = pairingStorage
        self.logger = logger
    }

    public func delete(topic: String) async throws {
        let reason = PairingReasonCode.userDisconnected
        let protocolMethod = PairingProtocolMethod.delete
        logger.debug("Will delete pairing for reason: message: \(reason.message) code: \(reason.code)")
        let request = RPCRequest(method: protocolMethod.method, params: reason)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)
        pairingStorage.delete(topic: topic)
        kms.deleteSymmetricKey(for: topic)
        networkingInteractor.unsubscribe(topic: topic)
    }
}
