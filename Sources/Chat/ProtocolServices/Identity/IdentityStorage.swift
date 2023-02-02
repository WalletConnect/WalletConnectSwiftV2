import Foundation

typealias IdentityKey = SigningPrivateKey
typealias InviteKey = SigningPrivateKey

final class IdentityStorage {

    private let keychain: KeychainStorageProtocol

    init(keychain: KeychainStorageProtocol) {
        self.keychain = keychain
    }

    func createIdentityKey(for account: Account) throws -> IdentityKey {
        let key = IdentityKey()
        try keychain.add(key, forKey: identityKeyIdentifier(for: account))
        return key
    }

    func createInviteKey(for account: Account) throws -> InviteKey {
        let key = InviteKey()
        try keychain.add(key, forKey: inviteKeyIdentifier(for: account))
        return key
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
