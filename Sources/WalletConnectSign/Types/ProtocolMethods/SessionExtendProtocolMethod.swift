import Foundation
import WalletConnectNetworking

struct SessionExtendProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionExtend"

    var requestConfig = RelayConfig(tag: 1106, prompt: false, ttl: 86400)

    var responseConfig = RelayConfig(tag: 1107, prompt: false, ttl: 86400)
}
