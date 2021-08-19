// 

import Foundation
import CryptoSwift

protocol HMACAutenticating {
    func validateAuthentication(for data: Data, with mac: Data, using symmetricKey: Data) throws
    func generateAuthenticationDigest(for data: Data, using symmetricKey: Data) throws -> Data
}

class HMACAutenticator: HMACAutenticating {
    func validateAuthentication(for data: Data, with mac: Data, using symmetricKey: Data) throws {
        let newMacDigest = try generateAuthenticationDigest(for: data, using: symmetricKey)
        if mac != newMacDigest {
            throw HMACAutenticatorError.invalidAuthenticationCode
        }
    }
    
    func generateAuthenticationDigest(for data: Data, using symmetricKey: Data)  throws -> Data {
        let algo = HMAC(key: symmetricKey.bytes, variant: .sha256)
        let digest = try algo.authenticate(data.bytes)
        return Data(digest)
    }
}
