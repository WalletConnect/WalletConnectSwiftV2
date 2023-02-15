import Foundation

final class IdentityStorage {

    private let keychain: KeychainStorageProtocol

    init(keychain: KeychainStorageProtocol) {
        self.keychain = keychain
    }

    @discardableResult
    func saveIdentityKey(
        _ key: SigningPrivateKey,
        for account: Account
    ) throws -> SigningPrivateKey {
        try keychain.add(key, forKey: identityKeyIdentifier(for: account))
        return key
    }

    @discardableResult
    func saveInviteKey(
        _ key: AgreementPublicKey,
        for account: Account
    ) throws -> AgreementPublicKey {
        try keychain.add(key, forKey: inviteKeyIdentifier(for: account))
        return key
    }

    func removeIdentityKey(for account: Account) throws {
        try keychain.delete(key: identityKeyIdentifier(for: account))
    }

    func removeInviteKey(for account: Account) throws {
        try keychain.delete(key: inviteKeyIdentifier(for: account))
    }

    func getIdentityKey(for account: Account) -> SigningPrivateKey? {
        return try? keychain.read(key: identityKeyIdentifier(for: account))
    }

    func getInviteKey(for account: Account) -> AgreementPublicKey? {
        return try? keychain.read(key: inviteKeyIdentifier(for: account))
    }
}

private extension IdentityStorage {

    func identityKeyIdentifier(for account: Account) -> String {
        return "com.walletconnect.chat.identity.\(account.absoluteString)"
    }

    func inviteKeyIdentifier(for account: Account) -> String {
        return "com.walletconnect.chat.invite.\(account.absoluteString)"
    }
}
