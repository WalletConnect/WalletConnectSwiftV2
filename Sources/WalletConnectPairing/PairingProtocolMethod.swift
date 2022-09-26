import Foundation
import WalletConnectNetworking

struct PairingPingProtocolMethod: ProtocolMethod {
    var method: String = "wc_pairingPing"

    var request = RelayConfigrable(tag: 1002, prompt: false)

    var response = RelayConfigrable(tag: 1003, prompt: false)
}
