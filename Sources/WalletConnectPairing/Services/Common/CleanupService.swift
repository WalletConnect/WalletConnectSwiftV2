import Foundation

final class CleanupService {

    private let pairingStore: WCPairingStorage
    private let kms: KeyManagementServiceProtocol

    init(pairingStore: WCPairingStorage, kms: KeyManagementServiceProtocol) {
        self.pairingStore = pairingStore
        self.kms = kms
    }

    func cleanup() throws {
        pairingStore.deleteAll()
        try kms.deleteAll()
    }
}
