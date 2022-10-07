import WalletConnectKMS
import WalletConnectUtils

extension WalletConnectURI {

    public static func stub(isController: Bool = false) -> WalletConnectURI {
        WalletConnectURI(
            topic: String.generateTopic(),
            symKey: SymmetricKey().hexRepresentation,
            relay: RelayProtocolOptions(protocol: "", data: nil)
        )
    }
}
