import Foundation

struct NotifyDeleteProtocolMethod: ProtocolMethod {
    let method: String = "wc_notifyDelete"

    let requestConfig = RelayConfig(tag: 4004, prompt: false, ttl: 86400)

    let responseConfig = RelayConfig(tag: 4005, prompt: false, ttl: 86400)
}
