import Foundation
import CryptoKit

protocol GenericPasswordConvertible {
    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes
    var rawRepresentation: Data { get }
}

extension Curve25519.KeyAgreement.PrivateKey: GenericPasswordConvertible {}

extension Data: GenericPasswordConvertible {
    
    init<D>(rawRepresentation data: D) throws where D : ContiguousBytes {
        self = data.withUnsafeBytes { Data($0) }
    }
    
    var rawRepresentation: Data {
        self
    }
}
