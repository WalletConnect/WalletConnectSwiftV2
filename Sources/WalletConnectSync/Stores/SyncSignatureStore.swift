import Foundation
import Combine

final class SyncSignatureStore {

    private let keychain: KeychainStorageProtocol

    init(keychain: KeychainStorageProtocol) {
        self.keychain = keychain
    }

    func saveSignature(_ key: String, for account: Account) throws {
        try keychain.add(key, forKey: signatureIdentifier(for: account))
    }

    func getSignature(for account: Account) throws -> String {
        let identifier = signatureIdentifier(for: account)

        guard let key: String = try? keychain.read(key: identifier)
        else { throw Errors.signatureNotFound }

        return key
    }

    func isSignatureExists(account: Account) -> Bool {
        return (try? getSignature(for: account)) != nil
    }
}

private extension SyncSignatureStore {

    enum Errors: Error {
        case signatureNotFound
    }

    func signatureIdentifier(for account: Account) -> String {
        return "com.walletconnect.sync.signature.\(account.absoluteString)"
    }
}
