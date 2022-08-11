import Foundation
import WalletConnectKMS
import WalletConnectUtils
import WalletConnectPairing

final class CleanupService {

    private let pairingStore: WCPairingStorage
    private let sessionStore: WCSessionStorage
    private let kms: KeyManagementServiceProtocol
    private let sessionToPairingTopic: CodableStore<String>

    init(pairingStore: WCPairingStorage, sessionStore: WCSessionStorage, kms: KeyManagementServiceProtocol, sessionToPairingTopic: CodableStore<String>) {
        self.pairingStore = pairingStore
        self.sessionStore = sessionStore
        self.sessionToPairingTopic = sessionToPairingTopic
        self.kms = kms
    }

    func cleanup() throws {
        pairingStore.deleteAll()
        sessionStore.deleteAll()
        sessionToPairingTopic.deleteAll()
        try kms.deleteAll()
    }
}
