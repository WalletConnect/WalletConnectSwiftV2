import Foundation
import WalletConnectNetworking

struct AuthRequestProtocolMethod: ProtocolMethod {
    var method: String = "wc_authRequest"

    var requestConfig = RelayConfig(tag: 3000, prompt: true, ttl: 86400)

    var responseConfig = RelayConfig(tag: 3001, prompt: false, ttl: 86400)
}


struct PairingPingProtocolMethod: ProtocolMethod {
    var method: String = "wc_pairingPing"

    var requestConfig = RelayConfig(tag: 1002, prompt: false, ttl: 30)

    var responseConfig = RelayConfig(tag: 1003, prompt: false, ttl: 30)
}


struct PairingDeleteProtocolMethod: ProtocolMethod {
    var method: String = "wc_pairingDelete"

    var requestConfig = RelayConfig(tag: 1000, prompt: false, ttl: 86400)

    var responseConfig = RelayConfig(tag: 1001, prompt: false, ttl: 86400)
}
