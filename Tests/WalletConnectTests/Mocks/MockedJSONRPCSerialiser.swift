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
