import Foundation
import Web3

actor EIP191Verifier {

    func verify(signature: Data, message: Data, address: String) async throws {
        let sig = decompose(signature: signature)
        let publicKey = try EthereumPublicKey.init(
            message: message.bytes,
            v: EthereumQuantity(quantity: BigUInt(sig.v)),
            r: EthereumQuantity(sig.r),
            s: EthereumQuantity(sig.s)
        )
        try verifyPublicKey(publicKey, address: address)
    }

    private func decompose(signature: Data) -> Signer.Signature {
        let v = signature.bytes[signature.count-1]
        let r = signature.bytes[0..<32]
        let s = signature.bytes[32..<64]
        return (UInt(v), [UInt8](r), [UInt8](s))
    }

    private func verifyPublicKey(_ publicKey: EthereumPublicKey, address: String) throws {
        guard publicKey.address.hex(eip55: false) == address.lowercased() else {
            throw Errors.invalidSignature
        }
    }
}

extension EIP191Verifier {

    enum Errors: Error {
        case invalidSignature
    }
}
