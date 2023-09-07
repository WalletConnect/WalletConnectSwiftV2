import Foundation

struct NotifyMessageProtocolMethod: ProtocolMethod {
    let method: String = "wc_notifyMessage"

    let requestConfig: RelayConfig = RelayConfig(tag: 4002, prompt: true, ttl: 2592000)

    let responseConfig: RelayConfig = RelayConfig(tag: 4003, prompt: false, ttl: 2592000)
}
