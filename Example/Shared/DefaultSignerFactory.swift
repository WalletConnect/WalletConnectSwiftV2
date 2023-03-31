import Foundation
import CryptoSwift
import Web3
import Auth

public struct DefaultSignerFactory: SignerFactory {

    public func createEthereumSigner() -> EthereumSigner {
        return Web3Signer()
    }
}

public struct Web3Signer: EthereumSigner {

    public func sign(message: Data, with key: Data) throws -> EthereumSignature {
        let privateKey = try EthereumPrivateKey(privateKey: [UInt8](key))
        let signature = try privateKey.sign(message: message.bytes)
        return EthereumSignature(v: UInt8(signature.v), r: signature.r, s: signature.s)
    }
}
