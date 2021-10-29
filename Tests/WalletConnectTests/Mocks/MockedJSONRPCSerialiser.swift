// 

import Foundation
@testable import WalletConnect

class MockedJSONRPCSerialiser: JSONRPCSerialising {

    var codec: Codec
    var deserialised: Any!
    var serialised: String!
    
    init(codec: Codec = MockedCodec()) {
        self.codec = codec
    }
    
    func serialise(topic: String, encodable: Encodable) throws -> String {
        try serialise(json: try encodable.json(), agreementKeys: Crypto.X25519.AgreementKeys(sharedSecret: Data(), publicKey: Data()))
    }
    func tryDeserialise<T: Codable>(topic: String, message: String) -> T? {
        try? deserialise(message: message, symmetricKey: Data())
    }
    func deserialiseJsonRpc(topic: String, message: String) throws -> Result<JSONRPCResponse<AnyCodable>, JSONRPCError> {
        .success(try deserialise(message: message, symmetricKey: Data()))
    }
    
    func deserialise<T>(message: String, symmetricKey: Data) throws -> T where T : Codable {
        if let deserialisedModel = deserialised as? T {
            return deserialisedModel
        } else {
            throw NSError.mock()
        }
    }
    
    func deserialise<T>(message: String, symmetricKey: Data) throws -> T where T : Codable {
        if let deserialised = deserialised as? T {
            return deserialised
        } else {
            throw "Deserialisation Error"
        }
    }
    
    func serialise(json: String, agreementKeys: Crypto.X25519.AgreementKeys) throws -> String {
        return serialised
    }

}
