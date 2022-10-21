import Foundation
import WalletConnectNetworking

struct SessionUpdateProtocolMethod: ProtocolMethod {
    let method: String = "wc_sessionUpdate"

    let requestConfig = RelayConfig(tag: 1104, prompt: false, ttl: 86400)

    let responseConfig = RelayConfig(tag: 1105, prompt: false, ttl: 86400)
}
