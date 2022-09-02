
import Foundation
import WalletConnectNetworking
import JSONRPC
import WalletConnectKMS
import WalletConnectUtils
import WalletConnectPairing

class DisconnectPairService {
    enum Errors: Error {
        case pairingNotFound
    }
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
        guard pairingStorage.hasPairing(forTopic: topic) else { throw Errors.pairingNotFound}
        let reason = AuthError.userDisconnected
        logger.debug("Will delete pairing for reason: message: \(reason.message) code: \(reason.code)")
        let request = RPCRequest(method: AuthProtocolMethods.pairingDelete.rawValue, params: reason)
        try await networkingInteractor.request(request, topic: topic, tag: AuthProtocolMethods.pairingDelete.requestTag)
        pairingStorage.delete(topic: topic)
        kms.deleteSymmetricKey(for: topic)
        networkingInteractor.unsubscribe(topic: topic)
    }
}


enum AuthProtocolMethods: String {
    case authRequest = "wc_authRequest"
    case pairingDelete = "wc_pairingDelete"
    case pairingPing = "wc_pairingPing"

    var requestTag: Int {
        switch self {
        case .authRequest:
            return 3000
        case .pairingDelete:
            return 1000
        case .pairingPing:
            return 1002
        }
    }

    var responseTag: Int {
        switch self {
        case .authRequest:
            return 3001
        case .pairingDelete:
            return 1001
        case .pairingPing:
            return 1003
        }
    }
}
