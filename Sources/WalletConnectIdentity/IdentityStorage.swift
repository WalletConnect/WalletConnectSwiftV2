import Foundation

public final class IdentityStorage {

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

    func getIdentityKey(for account: Account) throws -> SigningPrivateKey {
        let identifier = identityKeyIdentifier(for: account)

        guard let key: SigningPrivateKey = try? keychain.read(key: identifier)
        else { throw Errors.identityKeyNotFound }

        return key
    }

    func getInviteKey(for account: Account) throws -> AgreementPublicKey {
        let identifier = inviteKeyIdentifier(for: account)

        guard let key: AgreementPublicKey = try? keychain.read(key: identifier)
        else { throw Errors.inviteKeyNotFound }

        return key
    }
}

private extension IdentityStorage {

    enum Errors: Error {
        case identityKeyNotFound
        case inviteKeyNotFound
    }

    func identityKeyIdentifier(for account: Account) -> String {
        return "com.walletconnect.identity.identity.\(account.absoluteString)"
    }

    func inviteKeyIdentifier(for account: Account) -> String {
        return "com.walletconnect.identity.invite.\(account.absoluteString)"
    }
}
