
import Foundation

struct NotifySubscribeProtocolMethod: ProtocolMethod {
    let method: String = "wc_notifySubscribe"

    let requestConfig: RelayConfig = RelayConfig(tag: 4000, prompt: false, ttl: 86400)

    let responseConfig: RelayConfig = RelayConfig(tag: 4001, prompt: false, ttl: 86400)
}
