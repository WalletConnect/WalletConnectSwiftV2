import Foundation
import Web3

struct Signer {

    typealias Signature = (v: UInt, r: [UInt8], s: [UInt8])

    init() {}

    func sign(message: Data, with key: Data) throws -> Data {
        let privateKey = try EthereumPrivateKey(privateKey: key.bytes)
        let signature = try privateKey.sign(message: message.bytes)
        return serialized(signature: signature)
    }

    private func serialized(signature: Signature) -> Data {
        return Data(signature.r + signature.s + [UInt8(signature.v)])
    }
}
