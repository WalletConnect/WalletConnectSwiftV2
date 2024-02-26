import Foundation

struct SessionAuthenticatedProtocolMethod: ProtocolMethod {
    let method: String = "wc_sessionAuthenticate"

    let requestConfig = RelayConfig(tag: 1116, prompt: true, ttl: 3600)

    let responseConfig = RelayConfig(tag: 1117, prompt: false, ttl: 3600)
}
