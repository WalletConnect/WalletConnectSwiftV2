import Foundation
import CryptoKit

// MARK: - CryptoKit extensions

extension Curve25519.KeyAgreement.PublicKey: Equatable {
    public static func == (lhs: Curve25519.KeyAgreement.PublicKey, rhs: Curve25519.KeyAgreement.PublicKey) -> Bool {
        lhs.rawRepresentation == rhs.rawRepresentation
    }
}

extension Curve25519.KeyAgreement.PrivateKey: Equatable {
    public static func == (lhs: Curve25519.KeyAgreement.PrivateKey, rhs: Curve25519.KeyAgreement.PrivateKey) -> Bool {
        lhs.rawRepresentation == rhs.rawRepresentation
    }
}

// MARK: - Public Key

public struct AgreementPublicKey: Equatable {
    
    fileprivate let key: Curve25519.KeyAgreement.PublicKey
    
    fileprivate init(publicKey: Curve25519.KeyAgreement.PublicKey) {
        self.key = publicKey
    }
    
    public init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
        self.key = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: data)
    }
    
    public var rawRepresentation: Data {
        key.rawRepresentation
    }
    
    public var hexRepresentation: String {
        key.rawRepresentation.toHexString()
    }
}

extension AgreementPublicKey: Codable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(key.rawRepresentation)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let buffer = try container.decode(Data.self)
        try self.init(rawRepresentation: buffer)
    }
}

// MARK: - Private Key

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
        try key.sharedSecretFromKeyAgreement(with: publicKeyShare.key)
    }
}


// MARK: - Symmetric Key

public struct SymmetricKey: GenericPasswordConvertible, Equatable {
    
    private let key: CryptoKit.SymmetricKey
    
    public var rawRepresentation: Data {
        key.withUnsafeBytes {Data(Array($0))}
    }
    
    public var hexRepresentation: String {
        rawRepresentation.toHexString()
    }

    public init(size: Size = .bits256) {
        switch size {
        case .bits256:
            self.key = CryptoKit.SymmetricKey(size: SymmetricKeySize.bits256)
        }
    }
    public init<D>(rawRepresentation data: D) throws where D : ContiguousBytes {
        self.key = CryptoKit.SymmetricKey(data: data)
    }
}

extension SymmetricKey {
    public enum Size {
        case bits256
    }
}
