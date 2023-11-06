import Foundation

struct SessionAuthenticatedProtocolMethod: ProtocolMethod {
    let method: String = "wc_sessionAuthenticated"

    let requestConfig = RelayConfig(tag: 1116, prompt: true, ttl: 86400)

    let responseConfig = RelayConfig(tag: 1117, prompt: false, ttl: 86400)
}

struct PairingPingProtocolMethod: ProtocolMethod {
    let method: String = "wc_pairingPing"

    let requestConfig = RelayConfig(tag: 1002, prompt: false, ttl: 30)

    let responseConfig = RelayConfig(tag: 1003, prompt: false, ttl: 30)
}

struct PairingDeleteProtocolMethod: ProtocolMethod {
    let method: String = "wc_pairingDelete"

    let requestConfig = RelayConfig(tag: 1000, prompt: false, ttl: 86400)

    let responseConfig = RelayConfig(tag: 1001, prompt: false, ttl: 86400)
}
