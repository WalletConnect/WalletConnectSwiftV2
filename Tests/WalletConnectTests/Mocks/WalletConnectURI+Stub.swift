import CryptoKit
@testable import WalletConnect

extension WalletConnectURI {
    
    static func stub(isController: Bool = false) -> WalletConnectURI {
        WalletConnectURI(
            topic: String.generateTopic()!,
            publicKey: Curve25519.KeyAgreement.PrivateKey().publicKey.rawRepresentation.toHexString(),
            isController: isController,
            relay: RelayProtocolOptions(protocol: "", params: nil)
        )
    }
}
