import Foundation

class DeleteSessionService {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let sessionStore: WCSessionStorage
    private let logger: ConsoleLogging

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         sessionStore: WCSessionStorage,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.sessionStore = sessionStore
        self.logger = logger
    }

    func delete(topic: String) async throws {
        let reasonCode = SignReasonCode.userDisconnected
        let protocolMethod = SessionDeleteProtocolMethod()
        let reason = SessionType.Reason(code: reasonCode.code, message: reasonCode.message)
        logger.debug("Will delete session for reason: message: \(reason.message) code: \(reason.code)")
        let request = RPCRequest(method: protocolMethod.method, params: reason)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)
        sessionStore.delete(topic: topic)
        logger.debug("Session disconnected")
        kms.deleteSymmetricKey(for: topic)
        networkingInteractor.unsubscribe(topic: topic)
    }
}
