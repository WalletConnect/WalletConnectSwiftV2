// 

import Foundation

protocol JSONRPCSerialising {
    var codec: Codec {get}
    func serialise(json: String, agreementKeys: Crypto.X25519.AgreementKeys) throws -> String
    func deserialise(message: String, symmetricKey: Data) throws -> ClientSynchJSONRPC
    func deserialise(message: String, symmetricKey: Data) throws -> JSONRPCResponse<AnyCodable>
    func deserialise(message: String, symmetricKey: Data) throws -> JSONRPCError 
}

class JSONRPCSerialiser: JSONRPCSerialising {
    var codec: Codec
    
    init(codec: Codec = AES_256_CBC_HMAC_SHA256_Codec()) {
        self.codec = codec
    }
    
    func deserialise<T: Codable>(message: String, symmetricKey: Data) throws -> T {
        let JSONRPCData = try decrypt(message: message, symmetricKey: symmetricKey)
        return try JSONDecoder().decode(T.self, from: JSONRPCData)
    }
    
    func deserialise(message: String, symmetricKey: Data) throws -> ClientSynchJSONRPC {
        let JSONRPCData = try decrypt(message: message, symmetricKey: symmetricKey)
        return try JSONDecoder().decode(ClientSynchJSONRPC.self, from: JSONRPCData)
    }
    
    func deserialise(message: String, symmetricKey: Data) throws -> JSONRPCResponse<AnyCodable> {
        let JSONRPCData = try decrypt(message: message, symmetricKey: symmetricKey)
        return try JSONDecoder().decode(JSONRPCResponse<AnyCodable>.self, from: JSONRPCData)
    }
    
    func deserialise(message: String, symmetricKey: Data) throws -> JSONRPCError {
        let JSONRPCData = try decrypt(message: message, symmetricKey: symmetricKey)
        return try JSONDecoder().decode(JSONRPCError.self, from: JSONRPCData)
    }
    
    func serialise(json: String, agreementKeys: Crypto.X25519.AgreementKeys) throws -> String {
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
