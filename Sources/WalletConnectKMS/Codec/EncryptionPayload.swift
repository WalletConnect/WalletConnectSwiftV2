// 

import Foundation

struct EncryptionPayload: Codable {
    var iv: Data
    var mac: Data
    var cipherText: Data
    
    static let ivLength = 16
    static let macLength = 32
}
