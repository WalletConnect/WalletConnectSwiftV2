import Foundation
import WalletConnectPairing

class DisconnectService {
    enum Errors: Error {
        case objectForTopicNotFound
    }

    private let deleteSessionService: DeleteSessionService
    private let sessionStorage: WCSessionStorage
    private let pairingClient: PairingClient

    init(deleteSessionService: DeleteSessionService,
         sessionStorage: WCSessionStorage,
         pairingClient: PairingClient) {
        self.deleteSessionService = deleteSessionService
        self.sessionStorage = sessionStorage
        self.pairingClient = pairingClient
    }

    func disconnect(topic: String) async throws {
        if let _ = try? pairingClient.getPairing(for: topic) {
            try await pairingClient.disconnect(topic: topic)
        } else if sessionStorage.hasSession(forTopic: topic) {
            try await deleteSessionService.delete(topic: topic)
        } else {
            throw Errors.objectForTopicNotFound
        }
    }
}
