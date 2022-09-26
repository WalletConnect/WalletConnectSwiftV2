import Foundation
import WalletConnectNetworking

struct SessionProposeProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionPropose"

    var requestConfig = RelayConfig(tag: 1100, prompt: true, ttl: 300)

    var responseConfig = RelayConfig(tag: 1101, prompt: false, ttl: 300)
}
