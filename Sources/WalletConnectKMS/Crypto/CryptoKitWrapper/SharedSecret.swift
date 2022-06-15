import Foundation
import CryptoKit

struct SharedSecret {
    private var sharedSecret: CryptoKit.SharedSecret
    var rawRepresentation: Data {
        return sharedSecret.withUnsafeBytes { return Data(Array($0)) }
    }

    init(sharedSecret: CryptoKit.SharedSecret) {
        self.sharedSecret = sharedSecret
    }

    func deriveSymmetricKey() -> SymmetricKey {
        let symKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: Data(), sharedInfo: Data(), outputByteCount: 32)
        return SymmetricKey(key: symKey)
    }
}
