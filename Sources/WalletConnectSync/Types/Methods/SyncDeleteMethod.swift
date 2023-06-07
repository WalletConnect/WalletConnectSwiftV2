import Foundation

struct SyncDeleteMethod: ProtocolMethod {
    let method: String = "wc_syncDel"

    let requestConfig = RelayConfig(tag: 5002, prompt: false, ttl: 2592000)

    let responseConfig = RelayConfig(tag: 5003, prompt: false, ttl: 2592000)
}
