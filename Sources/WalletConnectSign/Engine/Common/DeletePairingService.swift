import Foundation
import WalletConnectKMS
import WalletConnectUtils
import WalletConnectPairing

class DeletePairingService {
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
        let reasonCode = ReasonCode.userDisconnected
        let reason = SessionType.Reason(code: reasonCode.code, message: reasonCode.message)
        logger.debug("Will delete pairing for reason: message: \(reason.message) code: \(reason.code)")
        try await networkingInteractor.request(.wcSessionDelete(reason), onTopic: topic)
        pairingStorage.delete(topic: topic)
        kms.deleteSymmetricKey(for: topic)
        networkingInteractor.unsubscribe(topic: topic)
    }
}

