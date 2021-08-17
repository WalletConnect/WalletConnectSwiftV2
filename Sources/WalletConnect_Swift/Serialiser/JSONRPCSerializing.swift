// 

import Foundation

protocol JSONRPCSerialising {
    var codec: Codec {get}
    func serialise(json: String, key: String) -> String
    func deserialise(message: String, key: String) throws -> ClientSynchJSONRPC
}

class JSONRPCSerialiser: JSONRPCSerialising {
    var codec: Codec
    
    init(codec: Codec) {
        self.codec = codec
    }
    
    func deserialise(message: String, key: String) throws -> ClientSynchJSONRPC {
        let encryptionPayload = try deserialiseIntoPayload(message: message)
        let decryptedJSONRPC = codec.decode(payload: encryptionPayload, key: key)
        guard let JSONRPCData = decryptedJSONRPC.data(using: .utf8) else {
            throw DataConversionError.stringToDataFailed
        }
        return try JSONDecoder().decode(ClientSynchJSONRPC.self, from: JSONRPCData)
    }
    
    func serialise(json: String, key: String) -> String {
        let payload = codec.encode(plainText: json, key: key)
        return "\(payload.iv.string)\(payload.publicKey.string)\(payload.mac.string)\(payload.cipherText.string)"
    }
    
    func deserialiseIntoPayload(message: String) throws -> EncryptionPayload {
        let data = Data.fromHex(message)!
        guard data.count > EncryptionPayload.ivLength + EncryptionPayload.publicKeyLength + EncryptionPayload.macLength else {
            throw JSONRPCSerialiserError.messageToShort
        }
        let pubKeyRangeStartIndex = EncryptionPayload.ivLength
        let macStartIndex = pubKeyRangeStartIndex + EncryptionPayload.publicKeyLength
        let cipherTextStartIndex = macStartIndex + EncryptionPayload.macLength
        let iv = data.subdata(in: 0..<pubKeyRangeStartIndex).toHexString()
        let pubKey = data.subdata(in: pubKeyRangeStartIndex..<macStartIndex).toHexString()
        let mac = data.subdata(in: macStartIndex..<cipherTextStartIndex).toHexString()
        let cipherText = data.subdata(in: cipherTextStartIndex..<data.count)
        return EncryptionPayload(iv: HexString(iv), publicKey: HexString(pubKey), mac: HexString(mac), cipherText: HexString(cipherText))
    }
}
