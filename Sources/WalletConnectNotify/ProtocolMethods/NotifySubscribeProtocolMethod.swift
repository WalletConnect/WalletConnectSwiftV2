
import Foundation

struct NotifySubscribeProtocolMethod: ProtocolMethod {
    let method: String = "wc_notifySubscribe"

    let requestConfig: RelayConfig = RelayConfig(tag: 4006, prompt: true, ttl: 86400)

    let responseConfig: RelayConfig = RelayConfig(tag: 4007, prompt: true, ttl: 86400)
}
