import Foundation

public protocol EthereumSigner {
    func sign(message: Data, with key: Data) throws -> EthereumSignature
    func recover(signature: EthereumSignature, message: Data) throws -> EthereumPubKey
    func keccak256(_ data: Data) -> Data
}
