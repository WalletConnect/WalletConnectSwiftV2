import Foundation
import WalletConnectPairing

class DisconnectService {
    enum Errors: Error {
        case objectForTopicNotFound
    }

    private let deletePairingService: DeletePairingService
    private let deleteSessionService: DeleteSessionService
    private let pairingStorage: WCPairingStorage
    private let sessionStorage: WCSessionStorage

    init(deletePairingService: DeletePairingService,
         deleteSessionService: DeleteSessionService,
         pairingStorage: WCPairingStorage,
         sessionStorage: WCSessionStorage) {
        self.deletePairingService = deletePairingService
        self.deleteSessionService = deleteSessionService
        self.pairingStorage = pairingStorage
        self.sessionStorage = sessionStorage
    }

    func disconnect(topic: String) async throws {
        if pairingStorage.hasPairing(forTopic: topic) {
            try await deletePairingService.delete(topic: topic)
        } else if sessionStorage.hasSession(forTopic: topic) {
            try await deleteSessionService.delete(topic: topic)
        } else {
            throw Errors.objectForTopicNotFound
        }
    }
}
