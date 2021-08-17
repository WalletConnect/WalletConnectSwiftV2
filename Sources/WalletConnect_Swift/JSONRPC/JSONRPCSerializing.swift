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

struct ClientSynchJSONRPC: Codable {
    let id: Int64
    let jsonrpc: String
    let method: Method
    let params: Params
    
    enum CodingKeys: CodingKey {
        case id
        case jsonrpc
        case method
        case params
    }
    
    internal init(id: Int64, jsonrpc: String, method: Method, params: Params) {
        self.id = id
        self.jsonrpc = jsonrpc
        self.method = method
        self.params = params
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        method = try container.decode(Method.self, forKey: .method)
        switch method {
        case .pairingApprove:
            let paramsValue = try container.decode(PairingApproveParams.self, forKey: .params)
            params = .pairingApprove(paramsValue)
        case .pairingReject:
            let paramsValue = try container.decode(PairingRejectParams.self, forKey: .params)
            params = .pairingReject(paramsValue)
        }
    }
}

extension ClientSynchJSONRPC {
    enum Method: String, Codable {
        case pairingApprove = "wc_pairingApprove"
        case pairingReject = "wc_pairingReject"
    }
    
    enum Params: Codable, Equatable {
        case pairingApprove(PairingApproveParams)
        case pairingReject(PairingRejectParams)
        
        static func == (lhs: Params, rhs: Params) -> Bool {
            switch (lhs, rhs) {
            case (.pairingApprove(let lhsParam), .pairingApprove(let rhsParam)):
                return lhsParam == rhsParam
            case (.pairingReject(let lhsParam), pairingReject(let rhsParam)):
                return lhsParam == rhsParam
            default:
                return false
            }
        }
        
        init(from decoder: Decoder) throws {
            fatalError("forbidden")
        }
        
        func encode(to encoder: Encoder) throws {
            fatalError("forbidden")
        }
    }
}
