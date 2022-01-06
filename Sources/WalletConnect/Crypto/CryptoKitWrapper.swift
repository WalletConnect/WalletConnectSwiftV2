import Foundation
import CryptoKit

//protocol AgreementPublicKey {
////    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes
//    var rawRepresentation: Data { get }
//}
//
//protocol AgreementPrivateKey {
//    var publicKey: AgreementPublicKey { get }
//}
//
//extension Curve25519.KeyAgreement.PublicKey: AgreementPublicKey {}
//
//extension Curve25519.KeyAgreement.PrivateKey: AgreementPrivateKey {
//    var publicKey: AgreementPublicKey {
//        self.publicKey
//    }
//}



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
