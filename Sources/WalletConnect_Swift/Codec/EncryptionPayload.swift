// 

import Foundation

struct EncryptionPayload: Codable {
    var iv: String
    var publicKey: String
    var mac: String
    var cipherText: String
    
    static let ivLength = 16
    static let publicKeyLength = 32
    static let macLength = 32
}
