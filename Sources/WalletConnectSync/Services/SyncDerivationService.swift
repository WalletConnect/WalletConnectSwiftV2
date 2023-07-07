import Foundation

final class SyncDerivationService {

    private let syncStorage: SyncSignatureStore
    private let bip44: BIP44Provider
    private let kms: KeyManagementServiceProtocol

    init(
        syncStorage: SyncSignatureStore,
        bip44: BIP44Provider,
        kms: KeyManagementServiceProtocol
    ) {
        self.syncStorage = syncStorage
        self.bip44 = bip44
        self.kms = kms
    }

    func deriveTopic(account: Account, store: String) throws -> String {
        let signature = try syncStorage.getSignature(for: account)

        guard let signatureData = signature.data(using: .utf8) else {
            throw Errors.signatureIsNotUTF8
        }

        let slice = store.components(withMaxLength: 4)
            .compactMap { $0.data(using: .utf8) }
            .compactMap { UInt32($0.toHexString(), radix: 16) }

        let path: [DerivationPath] = [
            .hardened(77),
            .hardened(0),
            .notHardened(0)
        ] + slice.map { .notHardened($0) }

        let entropy = signatureData.sha256()
        let storeKey = bip44.derive(entropy: entropy, path: path)
        let topic = storeKey.sha256().toHexString()

        let symmetricKey = try SymmetricKey(rawRepresentation: storeKey)
        try kms.setSymmetricKey(symmetricKey, for: topic)

        return topic
    }
}

private extension SyncDerivationService {

    enum Errors: Error {
        case signatureIsNotUTF8
    }
}

fileprivate extension String {

    func components(withMaxLength length: Int) -> [String] {
        return stride(from: 0, to: count, by: length).map {
            let start = index(startIndex, offsetBy: $0)
            let end = index(start, offsetBy: length, limitedBy: endIndex) ?? endIndex
            return String(self[start..<end])
        }
    }
}
