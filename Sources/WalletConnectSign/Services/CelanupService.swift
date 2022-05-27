import Foundation
import WalletConnectKMS

final class CleanupService {
    
    private let pairingStore: WCPairingStorage
    private let sessionStore: WCSessionStorage
    private let kms: KeyManagementServiceProtocol
    
    init(pairingStore: WCPairingStorage, sessionStore: WCSessionStorage, kms: KeyManagementServiceProtocol) {
        self.pairingStore = pairingStore
        self.sessionStore = sessionStore
        self.kms = kms
    }
    
    func cleanup() throws {
        pairingStore.deleteAll()
        sessionStore.deleteAll()
        try kms.deleteAll()
    }
}
