import Foundation
import Web3
import CryptoSwift
import HDWalletKit
import WalletConnectSigner

struct DefaultBIP44Provider: BIP44Provider {

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
