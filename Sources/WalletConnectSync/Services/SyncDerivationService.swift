import Foundation

final class SyncDerivationService {

    private let crypto: CryptoProvider
    private let storage: SyncStorage
    private let kms: KeyManagementServiceProtocol

    init(crypto: CryptoProvider, storage: SyncStorage, kms: KeyManagementServiceProtocol) {
        self.crypto = crypto
        self.storage = storage
        self.kms = kms
    }

    func deriveTopic(account: Account, store: String) throws -> String {
        fatalError()

        // TODO: KMS setSymKey
    }
}
