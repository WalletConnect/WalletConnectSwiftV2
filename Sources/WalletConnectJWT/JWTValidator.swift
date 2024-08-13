import Foundation
import CryptoKit

public struct JWTValidator {

    private let jwtString: String

    public init(jwtString: String) {
        self.jwtString = jwtString
    }

    public func isValid(publicKey: SigningPublicKey) throws -> Bool {
        var components = jwtString.components(separatedBy: ".")

        guard components.count == 3 else { throw JWTError.undefinedFormat }

        let signature = components.removeLast()

        guard let unsignedData = components
            .joined(separator: ".")
            .data(using: .utf8)
        else { throw JWTError.invalidJWTString }

        let signatureData = try JWTEncoder.base64urlDecodedData(string: signature)
        return publicKey.isValid(signature: signatureData, for: unsignedData)
    }
}


public struct P256JWTValidator {

    private let jwtString: String

    public init(jwtString: String) {
        self.jwtString = jwtString
    }

    public func isValid(publicKey: P256.Signing.PublicKey) throws -> Bool {
        var components = jwtString.components(separatedBy: ".")

        guard components.count == 3 else { throw JWTError.undefinedFormat }

        let signature = components.removeLast()

        guard let unsignedData = components
            .joined(separator: ".")
            .data(using: .utf8)
        else { throw JWTError.invalidJWTString }

        let signatureData = try JWTEncoder.base64urlDecodedData(string: signature)

        let P256Signature = try P256.Signing.ECDSASignature(rawRepresentation: signatureData)

        return publicKey.isValidSignature(P256Signature, for: unsignedData)
    }
}
