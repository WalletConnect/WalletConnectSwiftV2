import Foundation
@testable import WalletConnectSigner

extension MessageVerifier {

    static func stub() -> MessageVerifier {
        return MessageVerifier(
            eip191Verifier: EIP191Verifier(crypto: Crypto()),
            eip1271Verifier: EIP1271Verifier(
                projectId: "",
                httpClient: HTTPNetworkClient(host: ""),
                crypto: Crypto()
            )
        )
    }

    struct Crypto: CryptoProvider {
        func derive(entropy: Data, path: [WalletConnectSigner.DerivationPath]) -> Data {
            return Data()
        }

        func keccak256(_ data: Data) -> Data {
            return Data()
        }

        func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
            return Data()
        }
    }
}
