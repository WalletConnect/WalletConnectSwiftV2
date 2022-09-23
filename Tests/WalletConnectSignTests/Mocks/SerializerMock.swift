// 

import Foundation
import WalletConnectUtils
@testable import WalletConnectKMS
@testable import WalletConnectSign

class SerializerMock: Serializing {
    var deserialized: Any!
    var serialized: String = ""

    func serialize(topic: String, encodable: Encodable, envelopeType: Envelope.EnvelopeType) throws -> String {
        try serialize(json: try encodable.json(), agreementKeys: AgreementKeys.stub())
    }
    func deserialize<T: Codable>(topic: String, encodedEnvelope: String) throws -> T {
        return try deserialize(message: encodedEnvelope, symmetricKey: Data())
    }
    func deserializeJsonRpc(topic: String, message: String) throws -> Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse> {
        .success(try deserialize(message: message, symmetricKey: Data()))
    }

    func deserialize<T>(message: String, symmetricKey: Data) throws -> T where T: Codable {
        if let deserializedModel = deserialized as? T {
            return deserializedModel
        } else {
            throw NSError.mock()
        }
    }

    func serialize(json: String, agreementKeys: AgreementKeys) throws -> String {
        return serialized
    }

}
