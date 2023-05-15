
import Foundation

struct PushSubscribeProtocolMethod: ProtocolMethod {
    let method: String = "wc_pushSubscribe"

    let requestConfig: RelayConfig = RelayConfig(tag: 4006, prompt: true, ttl: 86400)

    let responseConfig: RelayConfig = RelayConfig(tag: 4007, prompt: true, ttl: 86400)
}
