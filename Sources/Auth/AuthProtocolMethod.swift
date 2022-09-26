import Foundation
import WalletConnectNetworking

struct AuthRequestProtocolMethod: ProtocolMethod {
    var method: String = "wc_authRequest"

    var request = RelayConfig(tag: 3000, prompt: true)

    var response = RelayConfig(tag: 3001, prompt: false)
}


struct PairingPingProtocolMethod: ProtocolMethod {
    var method: String = "wc_pairingPing"

    var request = RelayConfig(tag: 1002, prompt: false)

    var response = RelayConfig(tag: 1003, prompt: false)
}


struct PairingDeleteProtocolMethod: ProtocolMethod {
    var method: String = "wc_pairingDelete"

    var request = RelayConfig(tag: 1000, prompt: false)

    var response = RelayConfig(tag: 1001, prompt: false)
}
