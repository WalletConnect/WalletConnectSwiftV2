import Foundation
import CryptoKit

// MARK: - CryptoKit extensions

extension Curve25519.KeyAgreement.PublicKey: Equatable {
    public static func == (lhs: Curve25519.KeyAgreement.PublicKey, rhs: Curve25519.KeyAgreement.PublicKey) -> Bool {
        lhs.rawRepresentation == rhs.rawRepresentation
    }
}

public struct AgreementPublicKey: Equatable {
    
    fileprivate let key: Curve25519.KeyAgreement.PublicKey
    
    fileprivate init(publicKey: Curve25519.KeyAgreement.PublicKey) {
        self.key = publicKey
    }
    
    public init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
        self.key = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: data)
    }
    
    public init(hex: String) throws {
        let data = Data(hex: hex)
        try self.init(rawRepresentation: data)
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

