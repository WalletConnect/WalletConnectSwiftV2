import Foundation

public struct MessageVerifierFactory {

    public let crypto: CryptoProvider

    public init(crypto: CryptoProvider) {
        self.crypto = crypto
    }

    public func create() -> MessageVerifier {
        return create(projectId: Networking.projectId)
    }

    public func create(projectId: String) -> MessageVerifier {
        return MessageVerifier(eip191Verifier: EIP191Verifier(crypto: crypto), eip1271Verifier: EIP1271Verifier(projectId: projectId, httpClient: HTTPNetworkClient(host: "rpc.walletconnect.com"), crypto: crypto))
    }
}
