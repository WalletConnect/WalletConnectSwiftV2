import Foundation
import WalletConnectNetworking

struct AuthRequestProtocolMethod: ProtocolMethod {
    var method: String = "wc_authRequest"

    var requestConfig = RelayConfig(tag: 3000, prompt: true)

    var responseConfig = RelayConfig(tag: 3001, prompt: false)
}


struct PairingPingProtocolMethod: ProtocolMethod {
    var method: String = "wc_pairingPing"

    var requestConfig = RelayConfig(tag: 1002, prompt: false)

    var responseConfig = RelayConfig(tag: 1003, prompt: false)
}


struct PairingDeleteProtocolMethod: ProtocolMethod {
    var method: String = "wc_pairingDelete"

    var requestConfig = RelayConfig(tag: 1000, prompt: false)

    var responseConfig = RelayConfig(tag: 1001, prompt: false)
}
