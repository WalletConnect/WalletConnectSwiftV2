// 

import Foundation
@testable import WalletConnect_Swift

class MockedCodec: Codec {
    var hmacAuthenticator: HMACAutenticating
    
    var encryptionPayload: EncryptionPayload!
    var decodedJson: String!
    
    init(hmacAuthenticator: HMACAutenticating = HMACAutenticator()) {
        self.hmacAuthenticator = hmacAuthenticator
    }

    func encode(plainText: String, agreementKeys: X25519AgreementKeys) throws -> EncryptionPayload {
        return encryptionPayload
    }
    
    func decode(payload: EncryptionPayload, symmetricKey: Data) throws -> String {
        return decodedJson
    }
}
