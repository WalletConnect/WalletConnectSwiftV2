// 

import Foundation
import WalletConnectUtils
@testable import WalletConnect

class MockedJSONRPCSerialiser: JSONRPCSerialising {

    var codec: Codec
    var deserialised: Any!
    var serialised: String!
    
    init(codec: Codec = MockedCodec()) {
        self.codec = codec
    }
    
    func serialise(topic: String, encodable: Encodable) throws -> String {
        try serialise(json: try encodable.json(), agreementKeys: AgreementSecret(sharedSecret: Data(), publicKey: AgreementPrivateKey().publicKey))
    }
    func tryDeserialise<T: Codable>(topic: String, message: String) -> T? {
        try? deserialise(message: message, symmetricKey: Data())
    }
    func deserialiseJsonRpc(topic: String, message: String) throws -> Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse> {
        .success(try deserialise(message: message, symmetricKey: Data()))
    }
    
    func deserialise<T>(message: String, symmetricKey: Data) throws -> T where T : Codable {
        if let deserialisedModel = deserialised as? T {
            return deserialisedModel
        } else {
            throw NSError.mock()
        }
    }
    
    func serialise(json: String, agreementKeys: AgreementSecret) throws -> String {
        return serialised
    }

}
