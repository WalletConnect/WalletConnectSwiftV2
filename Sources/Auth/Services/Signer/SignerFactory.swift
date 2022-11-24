import Foundation

public protocol SignerFactory {
    func createEthereum() -> EthereumSigner
}
