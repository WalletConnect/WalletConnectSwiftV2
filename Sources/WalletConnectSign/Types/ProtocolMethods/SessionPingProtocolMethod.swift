import Foundation
import WalletConnectNetworking

struct SessionPingProtocolMethod: ProtocolMethod {
    let method: String = "wc_sessionPing"

    let requestConfig = RelayConfig(tag: 1114, prompt: false, ttl: 30)

    let responseConfig = RelayConfig(tag: 1115, prompt: false, ttl: 30)
}
