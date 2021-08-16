// 

import Foundation
@testable import WalletConnect_Swift

struct MockedCodec: Codec {
    var encryptionPayload: EncryptionPayload!
    var decodedJson: String!
    func encode(message: String, key: String) -> EncryptionPayload {
        return encryptionPayload
    }
    
    func decode(payload: EncryptionPayload, key: String) -> String {
        return decodedJson
    }
}
