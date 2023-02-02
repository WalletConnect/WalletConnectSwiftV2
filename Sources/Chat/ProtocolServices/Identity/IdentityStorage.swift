import Foundation

typealias IdentityKey = SigningPrivateKey
typealias InviteKey = SigningPrivateKey

final class IdentityStorage {

    private let keychain: KeychainStorageProtocol

    init(keychain: KeychainStorageProtocol) {
        self.keychain = keychain
    }

    func saveIdentityKey(_ key: IdentityKey, for account: Account) throws {
        try keychain.add(key, forKey: identityKeyIdentifier(for: account))
    }

    func saveInviteKey(_ key: InviteKey, for account: Account) throws {
        try keychain.add(key, forKey: inviteKeyIdentifier(for: account))
    }

    func getIdentityKey(for account: Account) -> IdentityKey? {
        return try? keychain.read(key: identityKeyIdentifier(for: account))
    }

    func getInviteKey(for account: Account) -> InviteKey? {
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
