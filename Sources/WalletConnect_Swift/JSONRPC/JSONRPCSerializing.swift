// 

import Foundation
enum JSONRPCSerialiserError: String, Error, CustomStringConvertible {
    case messageToShort = "message is to short"
    var description: String {
        return rawValue
    }
}
protocol JSONRPCSerialising {
    var codec: Codec {get}
    func serialise(json: String, key: String) -> String
    func deserialise(message: String, key: String) throws -> JSONRPCRequest<ClientSynchParams, ClientSynchMethod>
}

class JSONRPCSerialiser: JSONRPCSerialising {
    var codec: Codec
    
    init(codec: Codec) {
        self.codec = codec
    }
    
    func deserialise(message: String, key: String) throws -> JSONRPCRequest<ClientSynchParams, ClientSynchMethod> {
        let encryptionPayload = try deserialiseIntoPayload(message: message)
        let decryptedJSONRPC = codec.decode(payload: encryptionPayload, key: key)
        guard let JSONRPCData = decryptedJSONRPC.data(using: .utf8) else {
            throw DataConversionError.stringToDataFailed
        }
        return try JSONDecoder().decode(JSONRPCRequest<ClientSynchParams, ClientSynchMethod>.self, from: JSONRPCData)
    }
    
    func serialise(json: String, key: String) -> String {
        let payload = codec.encode(message: json, key: key)
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

protocol Codec {
    func encode(message: String, key: String) -> EncryptionPayload
    func decode(payload: EncryptionPayload, key: String) -> String
}

struct EncryptionPayload: Codable {
    var iv: HexString
    var publicKey: HexString
    var mac: HexString
    var cipherText: HexString
    
    static let ivLength = 16
    static let publicKeyLength = 32
    static let macLength = 32
}


enum ClientSynchMethod: String, Codable {
    case pairingApprove = "wc_pairingApprove"
    case pairingReject = "wc_pairingReject"
}

enum ClientSynchParams: Codable, Equatable {
    static func == (lhs: ClientSynchParams, rhs: ClientSynchParams) -> Bool {
        switch (lhs, rhs) {
        case (.pairingApprove(let lhsParam), .pairingApprove(let rhsParam)):
            return lhsParam == rhsParam
        case (.pairingReject(let lhsParam), pairingReject(let rhsParam)):
            return lhsParam == rhsParam
        default:
            return false
        }
    }
    
    case pairingApprove(PairingApproveParams)
    case pairingReject(PairingRejectParams)

    init(from decoder: Decoder) throws {
        fatalError("not implemented")
    }
    
    func encode(to encoder: Encoder) throws {
        fatalError("not implemented")
    }
    
}

struct PairingApproveParams: Codable, Equatable {
    let topic: String
    
    enum CodingKeys: CodingKey {
        case topic
    }
}

struct PairingRejectParams: Codable, Equatable {
    let reason: String
    
    enum CodingKeys: CodingKey {
        case reason
    }
}
