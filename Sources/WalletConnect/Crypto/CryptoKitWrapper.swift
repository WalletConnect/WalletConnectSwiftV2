import Foundation
import CryptoKit

extension Curve25519.KeyAgreement.PublicKey {
    
    var hexRepresentation: String {
        rawRepresentation.toHexString()
    }
}

extension Curve25519.KeyAgreement.PublicKey: Equatable {
    
    public static func == (lhs: Curve25519.KeyAgreement.PublicKey, rhs: Curve25519.KeyAgreement.PublicKey) -> Bool {
        lhs.rawRepresentation == rhs.rawRepresentation
    }
}

struct AgreementPublicKey: Equatable {
    
    fileprivate let key: Curve25519.KeyAgreement.PublicKey
    
    fileprivate init(publicKey: Curve25519.KeyAgreement.PublicKey) {
        self.key = publicKey
    }
    
    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
        self.key = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: data)
    }
    
    var rawRepresentation: Data {
        key.rawRepresentation
    }
    
    var hexRepresentation: String {
        key.rawRepresentation.toHexString()
    }
}

struct AgreementPrivateKey {

    private let key: Curve25519.KeyAgreement.PrivateKey
    
    init() {
        self.key = Curve25519.KeyAgreement.PrivateKey()
    }
    
    init<D>(rawRepresentation: D) throws where D : ContiguousBytes {
        self.key = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: rawRepresentation)
    }
    
    var rawRepresentation: Data {
        key.rawRepresentation
    }
    
    var publicKey: AgreementPublicKey {
        AgreementPublicKey(publicKey: key.publicKey)
    }
    
    func sharedSecretFromKeyAgreement(with publicKeyShare: AgreementPublicKey) throws -> SharedSecret {
        try key.sharedSecretFromKeyAgreement(with: publicKeyShare.key)
    }
}
