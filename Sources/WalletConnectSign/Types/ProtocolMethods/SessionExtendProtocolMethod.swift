import Foundation
import WalletConnectNetworking

struct SessionExtendProtocolMethod: ProtocolMethod {
    let method: String = "wc_sessionExtend"

    let requestConfig = RelayConfig(tag: 1106, prompt: false, ttl: 86400)

    let responseConfig = RelayConfig(tag: 1107, prompt: false, ttl: 86400)
}
