import Foundation
import WalletConnectNetworking

struct SessionRequestProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionRequest"

    var requestConfig = RelayConfig(tag: 1108, prompt: true, ttl: 300)

    var responseConfig = RelayConfig(tag: 1109, prompt: false, ttl: 300)
}
