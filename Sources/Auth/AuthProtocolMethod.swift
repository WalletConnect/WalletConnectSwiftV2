import Foundation
import WalletConnectNetworking

struct AuthRequestProtocolMethod: ProtocolMethod {
    var method: String = "wc_authRequest"

    var request = RelayConfigrable(tag: 3000, prompt: true)

    var response = RelayConfigrable(tag: 3001, prompt: false)
}


struct PairingPingProtocolMethod: ProtocolMethod {
    var method: String = "wc_pairingPing"

    var request = RelayConfigrable(tag: 1002, prompt: false)

    var response = RelayConfigrable(tag: 1003, prompt: false)
}


struct PairingDeleteProtocolMethod: ProtocolMethod {
    var method: String = "wc_pairingDelete"

    var request = RelayConfigrable(tag: 1000, prompt: false)

    var response = RelayConfigrable(tag: 1001, prompt: false)
}
