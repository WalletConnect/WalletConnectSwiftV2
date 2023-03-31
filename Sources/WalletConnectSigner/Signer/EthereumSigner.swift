import Foundation

public protocol EthereumSigner {
    func sign(message: Data, with key: Data) throws -> EthereumSignature
}
