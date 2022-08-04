import Foundation
import secp256k1

fileprivate typealias Signature = secp256k1.Recovery.ECDSASignature
fileprivate typealias RecoveryPublicKey = secp256k1.Recovery.PublicKey
fileprivate typealias SigningPublicKey = secp256k1.Signing.PublicKey
fileprivate typealias SigningPrivateKey = secp256k1.Signing.PrivateKey

struct Signer {

    func sign(message: Data, with privateKey: Data) throws -> Data {
        let key = try SigningPrivateKey(rawRepresentation: privateKey)
        let signature = try key.ecdsa.recoverableSignature(for: SHA256Digest(message.keccak256.bytes))
        return try signature.compactRepresentation.serialized
    }

    func isValid(signature: Data, message: Data, address: String) throws -> Bool {
        let digest = SHA256Digest(message.keccak256.bytes)
        let compact = signature.prefix(signature.count - 1)
        let recoveryId = Int32(signature[signature.count - 1])
        let recoverySignature = try Signature(compactRepresentation: compact, recoveryId: recoveryId)
        let publicKey = try RecoveryPublicKey(digest, signature: recoverySignature)
        let validator = try SigningPublicKey(rawRepresentation: publicKey.rawRepresentation, format: .compressed)
        let isValid = try validator.ecdsa.isValidSignature(recoverySignature.normalize, for: digest)
        let recoveredAddress = try SignerAddress.from(publicKey: publicKey.rawRepresentation)
        return isValid && recoveredAddress == address
    }
}
