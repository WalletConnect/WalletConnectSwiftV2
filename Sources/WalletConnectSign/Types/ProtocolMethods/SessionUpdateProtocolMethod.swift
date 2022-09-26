import Foundation
import WalletConnectNetworking

struct SessionUpdateProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionUpdate"

    var requestConfig = RelayConfig(tag: 1104, prompt: false, ttl: 86400)

    var responseConfig = RelayConfig(tag: 1105, prompt: false, ttl: 86400)
}

