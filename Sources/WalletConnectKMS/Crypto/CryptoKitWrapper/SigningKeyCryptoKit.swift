import Foundation
import CryptoKit

// MARK: - CryptoKit extensions

extension Curve25519.Signing.PublicKey: Equatable {
    public static func == (lhs: Curve25519.Signing.PublicKey, rhs: Curve25519.Signing.PublicKey) -> Bool {
        lhs.rawRepresentation == rhs.rawRepresentation
    }
}

extension Curve25519.Signing.PrivateKey: Equatable {
    public static func == (lhs: Curve25519.Signing.PrivateKey, rhs: Curve25519.Signing.PrivateKey) -> Bool {
        lhs.rawRepresentation == rhs.rawRepresentation
    }
}

// MARK: - Public Key

public struct SigningPublicKey: GenericPasswordConvertible, Equatable {
    public init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
        self.key = try Curve25519.Signing.PublicKey(rawRepresentation: data)
    }

    fileprivate let key: Curve25519.Signing.PublicKey

    fileprivate init(publicKey: Curve25519.Signing.PublicKey) {
        self.key = publicKey
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

    public func isValid(signature: Data, for digest: Data) -> Bool {
        return key.isValidSignature(signature, for: digest)
    }

    public var did: String {
        let key = DIDKey(rawData: rawRepresentation)
        return key.did(prefix: true, variant: .ED25519)
    }
}

extension SigningPublicKey: Codable {

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

public struct SigningPrivateKey: GenericPasswordConvertible, Equatable {

    private let key: Curve25519.Signing.PrivateKey

    public init() {
        self.key = Curve25519.Signing.PrivateKey()
    }

    public init<D>(rawRepresentation: D) throws where D: ContiguousBytes {
        self.key = try Curve25519.Signing.PrivateKey(rawRepresentation: rawRepresentation)
    }

    public var rawRepresentation: Data {
        key.rawRepresentation
    }

    public var publicKey: SigningPublicKey {
        SigningPublicKey(publicKey: key.publicKey)
    }

    public func signature(_ data: Data) throws -> Data {
        return try key.signature(for: data)
    }
}
