import Foundation
import Web3

public struct Signer {

    typealias Signature = (v: UInt, r: [UInt8], s: [UInt8])

    func sign(message: Data, with key: Data) throws -> Data {
        let prefixed = prefixed(message: message)
        let privateKey = try EthereumPrivateKey(privateKey: key.bytes)
        let signature = try privateKey.sign(message: prefixed.bytes)
        return serialized(signature: signature)
    }

    func isValid(signature: Data, message: Data, address: String) throws -> Bool {
        let sig = decompose(signature: signature)
        let prefixed = prefixed(message: message)
        let publicKey = try EthereumPublicKey(
            message: prefixed.bytes,
            v: EthereumQuantity(quantity: BigUInt(sig.v)),
            r: EthereumQuantity(sig.r),
            s: EthereumQuantity(sig.s)
        )
        return publicKey.address.hex(eip55: false) == address.lowercased()
    }

    private func decompose(signature: Data) -> Signature {
        let v = signature.bytes[signature.count-1]
        let r = signature.bytes[0..<32]
        let s = signature.bytes[32..<64]
        return (UInt(v), [UInt8](r), [UInt8](s))
    }

    private func serialized(signature: Signature) -> Data {
        return Data(signature.r + signature.s + [UInt8(signature.v)])
    }

    private func prefixed(message: Data) -> Data {
        return "\u{19}Ethereum Signed Message:\n\(message.count)"
            .data(using: .utf8)! + message
    }
}
