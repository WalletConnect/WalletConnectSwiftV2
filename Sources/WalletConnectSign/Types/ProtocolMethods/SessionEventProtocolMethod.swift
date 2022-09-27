import Foundation
import WalletConnectNetworking

struct SessionEventProtocolMethod: ProtocolMethod {
    let method: String = "wc_sessionEvent"

    let requestConfig = RelayConfig(tag: 1110, prompt: true, ttl: 300)

    let responseConfig = RelayConfig(tag: 1111, prompt: false, ttl: 300)
}
