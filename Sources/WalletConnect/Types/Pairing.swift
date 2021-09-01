// 

import Foundation
import CryptoKit

class Pairing {
    var clientPrivateKey: Curve25519.KeyAgreement.PrivateKey!
    var sharedSecretyKey: SymmetricKey!
    static let defaultTtl = 2592000
}


