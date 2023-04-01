import Foundation

struct JWTValidator {

    let jwtString: String

    func isValid(publicKey: SigningPublicKey) throws -> Bool {
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
