import Foundation
import WalletConnectNetworking

struct SessionDeleteProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionDelete"

    var requestConfig = RelayConfig(tag: 1112, prompt: false, ttl: 86400)

    var responseConfig = RelayConfig(tag: 1113, prompt: false, ttl: 86400)
}

