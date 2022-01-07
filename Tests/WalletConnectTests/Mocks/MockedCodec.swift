// 

import Foundation
@testable import WalletConnect

class MockedCodec: Codec {
    var hmacAuthenticator: HMACAutenticating
    
    var encryptionPayload: EncryptionPayload!
    var decodedJson: String!
    
    init(hmacAuthenticator: HMACAutenticating = HMACAutenticator()) {
        self.hmacAuthenticator = hmacAuthenticator
    }

    func encode(plainText: String, agreementKeys: AgreementSecret) throws -> EncryptionPayload {
        return encryptionPayload
    }
    
    func decode(payload: EncryptionPayload, sharedSecret: Data) throws -> String {
        return decodedJson
    }
}
