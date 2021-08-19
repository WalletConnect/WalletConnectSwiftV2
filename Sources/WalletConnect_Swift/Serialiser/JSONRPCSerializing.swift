// 

import Foundation

protocol JSONRPCSerialising {
    var codec: Codec {get}
    func serialise(json: String, agreementKeys: X25519AgreementKeys) throws -> String
    func deserialise(message: String, symmetricKey: Data) throws -> ClientSynchJSONRPC
}

class JSONRPCSerialiser: JSONRPCSerialising {
    var codec: Codec
    
    init(codec: Codec) {
        self.codec = codec
    }
    
    func deserialise(message: String, symmetricKey: Data) throws -> ClientSynchJSONRPC {
        let encryptionPayload = try deserialiseIntoPayload(message: message)
        let decryptedJSONRPC = try codec.decode(payload: encryptionPayload, symmetricKey: symmetricKey)
        guard let JSONRPCData = decryptedJSONRPC.data(using: .utf8) else {
            throw DataConversionError.stringToDataFailed
        }
        return try JSONDecoder().decode(ClientSynchJSONRPC.self, from: JSONRPCData)
    }
    
    func serialise(json: String, agreementKeys: X25519AgreementKeys) throws -> String {
        let payload = try codec.encode(plainText: json, agreementKeys: agreementKeys)
        return "\(payload.iv)\(payload.publicKey)\(payload.mac)\(payload.cipherText)"
    }
    
    func deserialiseIntoPayload(message: String) throws -> EncryptionPayload {
        let data = Data(hex: message)
        guard data.count > EncryptionPayload.ivLength + EncryptionPayload.publicKeyLength + EncryptionPayload.macLength else {
            throw JSONRPCSerialiserError.messageToShort
        }
        let pubKeyRangeStartIndex = EncryptionPayload.ivLength
        let macStartIndex = pubKeyRangeStartIndex + EncryptionPayload.publicKeyLength
        let cipherTextStartIndex = macStartIndex + EncryptionPayload.macLength
        let iv = data.subdata(in: 0..<pubKeyRangeStartIndex).toHexString()
        let pubKey = data.subdata(in: pubKeyRangeStartIndex..<macStartIndex).toHexString()
        let mac = data.subdata(in: macStartIndex..<cipherTextStartIndex).toHexString()
        let cipherText = data.subdata(in: cipherTextStartIndex..<data.count).toHexString()
        return EncryptionPayload(iv: iv, publicKey: pubKey, mac: mac, cipherText: cipherText)
    }
}
