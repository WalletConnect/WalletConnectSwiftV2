import Foundation
import WalletConnectNetworking

struct PairingPingProtocolMethod: ProtocolMethod {
    var method: String = "wc_pairingPing"

    var request = RelayConfig(tag: 1002, prompt: false)

    var response = RelayConfig(tag: 1003, prompt: false)
}
