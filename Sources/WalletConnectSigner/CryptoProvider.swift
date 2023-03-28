import Foundation

public protocol CryptoProvider {
    func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data
    func keccak256(_ data: Data) -> Data
}
