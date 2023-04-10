import Foundation
import Auth
import Web3
import CryptoSwift
import HDWalletKit

struct DefaultCryptoProvider: CryptoProvider {

    public func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
        let publicKey = try EthereumPublicKey(
            message: message.bytes,
            v: EthereumQuantity(quantity: BigUInt(signature.v)),
            r: EthereumQuantity(signature.r),
            s: EthereumQuantity(signature.s)
        )
        return Data(publicKey.rawPublicKey)
    }

    public func keccak256(_ data: Data) -> Data {
        let digest = SHA3(variant: .keccak256)
        let hash = digest.calculate(for: [UInt8](data))
        return Data(hash)
    }

    public func derive(entropy: Data, path: [WalletConnectSigner.DerivationPath]) -> Data {
        let mnemonic = Mnemonic.create(entropy: entropy)
        let seed = Mnemonic.createSeed(mnemonic: mnemonic)
        let privateKey = PrivateKey(seed: seed, coin: .bitcoin)

        let derived = path.reduce(privateKey) { result, path in
            switch path {
            case .hardened(let index):
                return result.derived(at: .hardened(index))
            case .notHardened(let index):
                return result.derived(at: .notHardened(index))
            }
        }

        return derived.raw
    }
}
