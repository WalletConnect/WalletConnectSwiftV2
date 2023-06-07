import Foundation

struct SyncSetMethod: ProtocolMethod {
    let method: String = "wc_syncSet"

    let requestConfig = RelayConfig(tag: 5000, prompt: false, ttl: 2592000)

    let responseConfig = RelayConfig(tag: 5001, prompt: false, ttl: 2592000)
}
