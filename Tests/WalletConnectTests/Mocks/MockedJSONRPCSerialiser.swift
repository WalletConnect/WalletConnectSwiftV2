// 

import Foundation
@testable import WalletConnect

class MockedJSONRPCSerialiser: JSONRPCSerialising {
    var codec: Codec
    var deserialised: ClientSynchJSONRPC!
    var serialised: String!
    init(codec: Codec = MockedCodec()) {
        self.codec = codec
    }
    func serialise(json: String, agreementKeys: Crypto.X25519.AgreementKeys) throws -> String {
        return serialised
    }
    
    func deserialise(message: String, symmetricKey: Data) throws -> ClientSynchJSONRPC {
        return deserialised
    }
}
