import Foundation
import WalletConnectPairing

struct PushDeleteProtocolMethod: ProtocolMethod {
    let method: String = "wc_pushDelete"

    let requestConfig = RelayConfig(tag: 4004, prompt: false, ttl: 86400)

    let responseConfig = RelayConfig(tag: 4005, prompt: false, ttl: 86400)
}
