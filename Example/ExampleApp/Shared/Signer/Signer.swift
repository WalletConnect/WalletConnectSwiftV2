import Foundation
import Commons
import WalletConnectSign

class Signer {

    private init() {}

    static func sign(request: Request) -> AnyCodable {
        switch request.method {
        case "personal_sign":
            return ETHSigner.personalSign(request.params)

        case "eth_signTypedData":
            return ETHSigner.signTypedData(request.params)

        case "eth_sendTransaction":
            return ETHSigner.sendTransaction(request.params)

        case "solana_signTransaction":
            return SOLSigner.signTransaction(request.params)
        default:
            fatalError("not implemented")
        }
    }
}
