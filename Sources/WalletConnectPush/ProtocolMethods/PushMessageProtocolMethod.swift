import Foundation
import WalletConnectPairing

struct PushMessageProtocolMethod: ProtocolMethod {
    let method: String = "wc_pushMessage"

    let requestConfig: RelayConfig = RelayConfig(tag: 4002, prompt: true, ttl: 86400)

    let responseConfig: RelayConfig = RelayConfig(tag: 4002, prompt: true, ttl: 86400)
}
