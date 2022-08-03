import Foundation
import secp256k1

fileprivate typealias Signature = secp256k1.Recovery.ECDSASignature
fileprivate typealias RecoveryPublicKey = secp256k1.Recovery.PublicKey
fileprivate typealias SigningPublicKey = secp256k1.Signing.PublicKey
fileprivate typealias SigningPrivateKey = secp256k1.Signing.PrivateKey

struct Signer {

    func sign(message: Data, with privateKey: Data) throws -> Data {
        let key = try SigningPrivateKey(rawRepresentation: privateKey)
        let signature = try key.ecdsa.recoverableSignature(for: message)
        return signature.rawRepresentation
    }

    func isValid(signature: Data, message: Data, address: String) throws -> Bool {
        let recoverySignature = try Signature(rawRepresentation: signature)
        let publicKey = try RecoveryPublicKey(message, signature: recoverySignature)
        let validator = try SigningPublicKey(rawRepresentation: publicKey.rawRepresentation, format: .compressed)
        let isValid = try validator.ecdsa.isValidSignature(recoverySignature.normalize, for: message)
        let recoveredAddress = try SignerAddress.from(publicKey: publicKey.rawRepresentation)
        return isValid && recoveredAddress == address
    }
}
