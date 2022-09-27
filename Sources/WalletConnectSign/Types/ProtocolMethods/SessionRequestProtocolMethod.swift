import Foundation
import WalletConnectNetworking

struct SessionRequestProtocolMethod: ProtocolMethod {
    let method: String = "wc_sessionRequest"

    let requestConfig = RelayConfig(tag: 1108, prompt: true, ttl: 300)

    let responseConfig = RelayConfig(tag: 1109, prompt: false, ttl: 300)
}
