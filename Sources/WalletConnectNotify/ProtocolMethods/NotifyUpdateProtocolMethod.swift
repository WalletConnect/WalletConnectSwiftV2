
import Foundation

struct NotifyUpdateProtocolMethod: ProtocolMethod {
    let method: String = "wc_pushUpdate"

    let requestConfig: RelayConfig = RelayConfig(tag: 4008, prompt: true, ttl: 86400)

    let responseConfig: RelayConfig = RelayConfig(tag: 4009, prompt: true, ttl: 86400)
}

