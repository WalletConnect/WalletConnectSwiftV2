import WalletConnectKMS
import WalletConnectUtils

extension WalletConnectURI {

    public static func stub(isController: Bool = false) -> WalletConnectURI {
        let methods = ["wc_sessionPropose", "wc_sessionAuthenticate"]
        return WalletConnectURI(
            topic: String.generateTopic(),
            symKey: SymmetricKey().hexRepresentation,
            relay: RelayProtocolOptions(protocol: "", data: nil),
            methods: methods
        )
    }
}
