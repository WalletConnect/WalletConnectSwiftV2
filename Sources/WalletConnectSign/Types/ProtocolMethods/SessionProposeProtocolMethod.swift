import Foundation
import WalletConnectNetworking

struct SessionProposeProtocolMethod: ProtocolMethod {
    let method: String = "wc_sessionPropose"

    let requestConfig = RelayConfig(tag: 1100, prompt: true, ttl: 300)

    let responseConfig = RelayConfig(tag: 1101, prompt: false, ttl: 300)
}
