import Foundation
import WalletConnectNetworking

struct SessionDeleteProtocolMethod: ProtocolMethod {
    let method: String = "wc_sessionDelete"

    let requestConfig = RelayConfig(tag: 1112, prompt: false, ttl: 86400)

    let responseConfig = RelayConfig(tag: 1113, prompt: false, ttl: 86400)
}
