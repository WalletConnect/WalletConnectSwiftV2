import Foundation

public protocol EthereumSigner {
    func sign(message: Data, with key: Data) throws -> EthereumSignature
    func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data
    func keccak256(_ data: Data) -> Data
}
