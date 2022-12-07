import Foundation
import Auth

struct SignerFactoryMock: SignerFactory {

    func createEthereumSigner() -> EthereumSigner {
        return EthereumSignerMock()
    }
}

struct EthereumSignerMock: EthereumSigner {

    func sign(message: Data, with key: Data) throws -> EthereumSignature {
        return EthereumSignature(v: 0, r: [], s: [])
    }

    func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
        return Data()
    }

    func keccak256(_ data: Data) -> Data {
        return Data()
    }
}
