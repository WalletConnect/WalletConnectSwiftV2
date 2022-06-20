// 

import Foundation
import CryptoKit

public protocol Codec {
    func encode(plaintext: String, symmetricKey: Data, nonce: ChaChaPoly.Nonce) throws -> String
    func decode(sealboxString: String, symmetricKey: Data) throws -> Data
}
public extension Codec {
    func encode(plaintext: String, symmetricKey: Data, nonce: ChaChaPoly.Nonce = ChaChaPoly.Nonce()) throws -> String {
        try encode(plaintext: plaintext, symmetricKey: symmetricKey, nonce: nonce)
    }
}

public class ChaChaPolyCodec: Codec {

    public init() {}
    /// nonce should always be random, exposed in parameter for testing purpose only
    public func encode(plaintext: String, symmetricKey: Data, nonce: ChaChaPoly.Nonce) throws -> String {
        let key = CryptoKit.SymmetricKey(data: symmetricKey)
        let dataToSeal = try data(string: plaintext)
        let sealBox = try ChaChaPoly.seal(dataToSeal, using: key, nonce: nonce)
        return sealBox.combined.base64EncodedString()
    }

    public func decode(sealboxString: String, symmetricKey: Data) throws -> Data {
        guard let sealboxData = Data(base64Encoded: sealboxString) else {
            throw CodecError.malformedSealbox
        }
        let key = CryptoKit.SymmetricKey(data: symmetricKey)
        let sealBox = try ChaChaPoly.SealedBox(combined: sealboxData)
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
