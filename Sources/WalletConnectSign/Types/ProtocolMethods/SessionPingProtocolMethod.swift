import Foundation
import WalletConnectNetworking

struct SessionPingProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionPing"

    var requestConfig = RelayConfig(tag: 1114, prompt: false, ttl: 30)

    var responseConfig = RelayConfig(tag: 1115, prompt: false, ttl: 30)
}

