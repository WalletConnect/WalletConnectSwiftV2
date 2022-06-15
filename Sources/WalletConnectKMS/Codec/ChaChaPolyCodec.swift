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
    /// nonce should always be random, exposed in parameter for testing purpose only
    func encode(plaintext: String, symmetricKey: Data, nonce: ChaChaPoly.Nonce) throws -> Data {
        let key = CryptoKit.SymmetricKey(data: symmetricKey)
        let dataToSeal = try data(string: plaintext)
        let sealBox = try ChaChaPoly.seal(dataToSeal, using: key, nonce: nonce)
        return sealBox.combined
    }
    
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
            throw CodecError.stringToDataFailed(string)
        }
    }
}
