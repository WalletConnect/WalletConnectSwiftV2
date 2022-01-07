import Foundation

protocol JSONRPCSerialising {
    func serialise(topic: String, encodable: Encodable) throws -> String
    func tryDeserialise<T: Codable>(topic: String, message: String) -> T?
    var codec: Codec {get}
}

class JSONRPCSerialiser: JSONRPCSerialising {
    
    private let crypto: Crypto
    let codec: Codec
    
    init(crypto: Crypto, codec: Codec = AES_256_CBC_HMAC_SHA256_Codec()) {
        self.crypto = crypto
        self.codec = codec
    }
    
    func serialise(topic: String, encodable: Encodable) throws -> String {
        let messageJson = try encodable.json()
        var message: String
        if let agreementKeys = try? crypto.getAgreementSecret(for: topic) {
            message = try encrypt(json: messageJson, agreementKeys: agreementKeys)
        } else {
            message = messageJson.toHexEncodedString(uppercase: false)
        }
        return message
    }
    
    func tryDeserialise<T: Codable>(topic: String, message: String) -> T? {
        do {
            let deserialisedJsonRpcRequest: T
            if let agreementKeys = try? crypto.getAgreementSecret(for: topic) {
                deserialisedJsonRpcRequest = try deserialise(message: message, symmetricKey: agreementKeys.sharedSecret)
            } else {
                let jsonData = Data(hex: message)
                deserialisedJsonRpcRequest = try JSONDecoder().decode(T.self, from: jsonData)
            }
            return deserialisedJsonRpcRequest
        } catch {
//            logger.debug("Type \(T.self) does not match the payload")
            return nil
        }
    }
    
    func deserialise<T: Codable>(message: String, symmetricKey: Data) throws -> T {
        let JSONRPCData = try decrypt(message: message, symmetricKey: symmetricKey)
        return try JSONDecoder().decode(T.self, from: JSONRPCData)
    }
    
    func encrypt(json: String, agreementKeys: AgreementSecret) throws -> String {
        let payload = try codec.encode(plainText: json, agreementKeys: agreementKeys)
        let iv = payload.iv.toHexString()
        let publicKey = payload.publicKey.toHexString()
        let mac = payload.mac.toHexString()
        let cipherText = payload.cipherText.toHexString()
        return "\(iv)\(publicKey)\(mac)\(cipherText)"
    }
    
    private func decrypt(message: String, symmetricKey: Data) throws -> Data {
        let encryptionPayload = try deserialiseIntoPayload(message: message)
        let decryptedJSONRPC = try codec.decode(payload: encryptionPayload, sharedSecret: symmetricKey)
        guard let JSONRPCData = decryptedJSONRPC.data(using: .utf8) else {
            throw DataConversionError.stringToDataFailed
        }
        return JSONRPCData
    }
    
    private func deserialiseIntoPayload(message: String) throws -> EncryptionPayload {
        let data = Data(hex: message)
        guard data.count > EncryptionPayload.ivLength + EncryptionPayload.publicKeyLength + EncryptionPayload.macLength else {
            throw JSONRPCSerialiserError.messageToShort
        }
        let pubKeyRangeStartIndex = EncryptionPayload.ivLength
        let macStartIndex = pubKeyRangeStartIndex + EncryptionPayload.publicKeyLength
        let cipherTextStartIndex = macStartIndex + EncryptionPayload.macLength
        let iv = data.subdata(in: 0..<pubKeyRangeStartIndex)
        let pubKey = data.subdata(in: pubKeyRangeStartIndex..<macStartIndex)
        let mac = data.subdata(in: macStartIndex..<cipherTextStartIndex)
        let cipherText = data.subdata(in: cipherTextStartIndex..<data.count)
        return EncryptionPayload(iv: iv, publicKey: pubKey, mac: mac, cipherText: cipherText)
    }
}
