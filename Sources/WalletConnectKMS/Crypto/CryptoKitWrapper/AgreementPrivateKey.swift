
import CryptoKit
import Foundation

// MARK: - CryptoKit extensions

extension Curve25519.KeyAgreement.PrivateKey: Equatable {
    public static func == (lhs: Curve25519.KeyAgreement.PrivateKey, rhs: Curve25519.KeyAgreement.PrivateKey) -> Bool {
        lhs.rawRepresentation == rhs.rawRepresentation
    }
}

public struct AgreementPrivateKey: GenericPasswordConvertible, Equatable {

    private let key: Curve25519.KeyAgreement.PrivateKey
    
    public init() {
        self.key = Curve25519.KeyAgreement.PrivateKey()
    }
    
    public init<D>(rawRepresentation: D) throws where D : ContiguousBytes {
        self.key = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: rawRepresentation)
    }
    
    public var rawRepresentation: Data {
        key.rawRepresentation
    }
    
    public var publicKey: AgreementPublicKey {
        AgreementPublicKey(publicKey: key.publicKey)
    }
    
    func sharedSecretFromKeyAgreement(with publicKeyShare: AgreementPublicKey) throws -> SharedSecret {
        let sharedSecret = try key.sharedSecretFromKeyAgreement(with: publicKeyShare.key)
        return SharedSecret(sharedSecret: sharedSecret)
    }
}
