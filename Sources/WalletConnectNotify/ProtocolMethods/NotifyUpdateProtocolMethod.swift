
import Foundation

struct NotifyUpdateProtocolMethod: ProtocolMethod {
    let method: String = "wc_notifyUpdate"

    let requestConfig: RelayConfig = RelayConfig(tag: 4008, prompt: false, ttl: 86400)

    let responseConfig: RelayConfig = RelayConfig(tag: 4009, prompt: false, ttl: 86400)
}

