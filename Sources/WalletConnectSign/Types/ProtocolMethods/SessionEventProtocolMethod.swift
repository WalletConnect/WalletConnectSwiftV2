import Foundation
import WalletConnectNetworking

struct SessionEventProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionEvent"

    var requestConfig = RelayConfig(tag: 1110, prompt: true, ttl: 300)

    var responseConfig = RelayConfig(tag: 1111, prompt: false, ttl: 300)
}
