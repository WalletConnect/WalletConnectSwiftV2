import Foundation

typealias IdentityKey = SigningPrivateKey

final class AuthenticationStorage {

    private let kms: KeychainServiceProtocol

    init(kms: KeychainServiceProtocol) {
        self.kms = kms
    }
}
