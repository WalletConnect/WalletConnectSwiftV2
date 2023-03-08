import Foundation
import Commons
import WalletConnectSign

final class Signer {
    enum Errors: Error {
        case notImplemented
    }
    
    private init() {}

    static func sign(request: Request) throws -> AnyCodable {
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
            throw Signer.Errors.notImplemented
        }
    }
}

extension Signer.Errors: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notImplemented:   return "Requested method is not implemented"
        }
    }
}
