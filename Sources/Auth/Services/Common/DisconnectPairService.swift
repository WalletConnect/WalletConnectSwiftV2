
import Foundation
import WalletConnectNetworking
import WalletConnectKMS
import WalletConnectUtils
import WalletConnectPairing

class DisconnectPairService {
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
    }

    func disconnect(topic: String) async throws {
        let reason = AuthError.userDisconnected
        logger.debug("Will delete pairing for reason: message: \(reason.message) code: \(reason.code)")
        try await networkingInteractor.request(<#T##RPCRequest#>, topic: <#T##String#>, tag: <#T##Int#>, envelopeType: <#T##Envelope.EnvelopeType#>)
        pairingStorage.delete(topic: topic)
        kms.deleteSymmetricKey(for: topic)
        networkingInteractor.unsubscribe(topic: topic)
    }
}
