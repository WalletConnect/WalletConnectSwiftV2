import Foundation

public enum DerivationPath {
    case hardened(UInt32)
    case notHardened(UInt32)
}

public protocol CryptoProvider {
    func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data
    func keccak256(_ data: Data) -> Data
    func derive(entropy: Data, path: [DerivationPath]) -> Data
}
