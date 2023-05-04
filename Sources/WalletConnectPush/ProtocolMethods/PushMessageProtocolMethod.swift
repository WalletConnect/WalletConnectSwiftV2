import Foundation
import WalletConnectPairing

struct PushMessageProtocolMethod: ProtocolMethod {
    let method: String = "wc_pushMessage"

    let requestConfig: RelayConfig = RelayConfig(tag: 4002, prompt: true, ttl: 2592000)

    let responseConfig: RelayConfig = RelayConfig(tag: 4003, prompt: true, ttl: 2592000)
}
