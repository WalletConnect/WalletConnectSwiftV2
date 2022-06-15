@testable import WalletConnectSign
@testable import WalletConnectKMS
import CryptoKit

extension WalletConnectURI {

    static func stub(isController: Bool = false) -> WalletConnectURI {
        WalletConnectURI(
            topic: String.generateTopic(),
            symKey: SymmetricKey().hexRepresentation,
            relay: RelayProtocolOptions(protocol: "", data: nil)
        )
    }
}
