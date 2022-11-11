import Foundation
import Commons
import WalletConnectSign

class Signer {

    private init() {}

    static func sign(request: Request) -> AnyCodable {
        switch request.method {
        case "personal_sign":
            return EthereumSigner.personalSign(request.params)

        case "eth_signTypedData":
            return EthereumSigner.signTypedData(request.params)

        case "eth_sendTransaction":
            return EthereumSigner.sendTransaction(request.params)

        case "solana_signTransaction":
            return SolanaSigner.signTransaction(request.params)
        default:
            fatalError("not implemented")
        }
    }
}
