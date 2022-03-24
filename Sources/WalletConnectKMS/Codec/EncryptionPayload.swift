// 

import Foundation

struct EncryptionPayload: Codable {
    var noce: Data
    var tag: Data
    var cipherText: Data
    
    static let ivLength = 16
    static let publicKeyLength = 32
    static let macLength = 32
}
