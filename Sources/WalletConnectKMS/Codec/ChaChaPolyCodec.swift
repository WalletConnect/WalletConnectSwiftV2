// 

import Foundation
import CryptoKit

protocol Codec {
    func encode(plaintext: String, symmetricKey: Data, nonce: ChaChaPoly.Nonce) throws -> Data
    func decode(sealbox: Data, symmetricKey: Data) throws -> Data
}
extension Codec {
    func encode(plaintext: String, symmetricKey: Data, nonce: ChaChaPoly.Nonce = ChaChaPoly.Nonce()) throws -> Data {
        try encode(plaintext: plaintext, symmetricKey: symmetricKey, nonce: nonce)
    }
}

class ChaChaPolyCodec: Codec {
    enum Errors: Error {
        case stringToDataFailed(String)
    }
    /// Secures the given plaintext message with encryption and an authentication tag.
    /// - Parameters:
    ///   - plaintext: plaintext to to encrypt
    ///   - symmetricKey: symmetric key for encryption
    ///   - nonce: nonce should always be random, exposed in parameter for testing purpose only
    /// - Returns: A combined element composed of the tag, the nonce, and the ciphertext.
    /// The data layout of the combined representation is: nonce, ciphertext, then tag.
    func encode(plaintext: String, symmetricKey: Data, nonce: ChaChaPoly.Nonce) throws -> Data {
        let key = CryptoKit.SymmetricKey(data: symmetricKey)
        let dataToSeal = try data(string: plaintext)
        let sealBox = try ChaChaPoly.seal(dataToSeal, using: key, nonce: nonce)
        return sealBox.combined
    }

    /// Decrypts the message and verifies its authenticity.
    /// - Parameters:
    ///   - sealbox: The sealed box to open.
    ///   - symmetricKey: The cryptographic key that was used to seal the message.
    /// - Returns: The original plaintext message that was sealed in the box, as long as the correct key is used and authentication succeeds. The call throws an error if decryption or authentication fail.
    func decode(sealbox: Data, symmetricKey: Data) throws -> Data {
        let sealboxCombined = sealbox
        let key = CryptoKit.SymmetricKey(data: symmetricKey)
        let sealBox = try ChaChaPoly.SealedBox(combined: sealboxCombined)
        return try ChaChaPoly.open(sealBox, using: key)
    }

    private func data(string: String) throws -> Data {
        if let data = string.data(using: .utf8) {
            return data
        } else {
            throw Errors.stringToDataFailed(string)
        }
    }
}
