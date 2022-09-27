import Foundation
import WalletConnectNetworking

struct SessionSettleProtocolMethod: ProtocolMethod {
    let method: String = "wc_sessionSettle"

    let requestConfig = RelayConfig(tag: 1102, prompt: false, ttl: 300)

    let responseConfig = RelayConfig(tag: 1103, prompt: false, ttl: 300)
}
