// 

import Foundation
@testable import WalletConnect

class MockedJSONRPCSerialiser: JSONRPCSerialising {
    func deserialise<T>(message: String, symmetricKey: Data) throws -> T where T : Decodable, T : Encodable {
        return deserialised as! T
    }
    
    var codec: Codec
    var deserialised: ClientSynchJSONRPC!
    var serialised: String!
    init(codec: Codec = MockedCodec()) {
        self.codec = codec
    }
    func serialise(json: String, agreementKeys: Crypto.X25519.AgreementKeys) throws -> String {
        return serialised
    }

}
