import Foundation
import WalletConnectPairing

struct PushProposeProtocolMethod: ProtocolMethod {
    let method: String = "wc_pushPropose"

    let requestConfig: RelayConfig = RelayConfig(tag: 4000, prompt: true, ttl: 86400)

    let responseConfig: RelayConfig = RelayConfig(tag: 4001, prompt: true, ttl: 86400)
}
