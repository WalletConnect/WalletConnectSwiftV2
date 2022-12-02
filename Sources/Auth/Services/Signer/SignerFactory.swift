import Foundation

public protocol SignerFactory {
    func createEthereumSigner() -> EthereumSigner
}
