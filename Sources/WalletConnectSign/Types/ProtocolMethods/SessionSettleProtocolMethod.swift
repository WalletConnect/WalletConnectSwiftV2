import Foundation
import WalletConnectNetworking

struct SessionSettleProtocolMethod: ProtocolMethod {
    var method: String = "wc_sessionSettle"

    var requestConfig = RelayConfig(tag: 1102, prompt: false, ttl: 300)

    var responseConfig = RelayConfig(tag: 1103, prompt: false, ttl: 300)
}
