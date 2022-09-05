import Foundation
import WalletConnectKMS
import WalletConnectUtils

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
        let reasonCode = ReasonCode.userDisconnected
        let reason = SessionType.Reason(code: reasonCode.code, message: reasonCode.message)
        logger.debug("Will delete session for reason: message: \(reason.message) code: \(reason.code)")
        try await networkingInteractor.request(.wcSessionDelete(reason), onTopic: topic)
        sessionStore.delete(topic: topic)
        kms.deleteSymmetricKey(for: topic)
        networkingInteractor.unsubscribe(topic: topic)
    }
}
