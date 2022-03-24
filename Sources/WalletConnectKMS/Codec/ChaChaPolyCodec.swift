// 

import Foundation
import CryptoKit

protocol Codec {
    func encode(plaintext: String, symmetricKey: Data) throws -> String
    func decode(sealboxString: String, symmetricKey: Data) throws -> Data
}

class ChaChaPolyCodec: Codec {
    
    func encode(plaintext: String, symmetricKey: Data) throws -> String {
        let key = CryptoKit.SymmetricKey(data: symmetricKey)
        print(key)
        let sealboxData = try ChaChaPoly.seal(data(string: plaintext), using: key).combined
        return sealboxData.base64EncodedString()
    }
    
    func decode(sealboxString: String, symmetricKey: Data) throws -> Data {
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

    private func string(data: Data) throws -> String {
        if let string = String(data: data, encoding: .utf8) {
            return string
        } else {
            throw CodecError.dataToStringFailed(data)
        }
    }
}
