import Foundation

enum PairingProtocolMethod: CaseIterable, ProtocolMethod {
    case ping
    case delete

    var method: String {
        switch self {
        case .ping:
            return "wc_pairingPing"
        case .delete:
            return "wc_pairingDelete"
        }
    }

    var requestConfig: RelayConfig {
        switch self {
        case .ping:
            return RelayConfig(tag: 1002, prompt: false, ttl: 30)
        case .delete:
            return RelayConfig(tag: 1003, prompt: false, ttl: 30)
        }
    }

    var responseConfig: RelayConfig {
        switch self {
        case .ping:
            return RelayConfig(tag: 1003, prompt: false, ttl: 30)
        case .delete:
            return RelayConfig(tag: 1001, prompt: false, ttl: 86400)
        }
    }
}

struct UnsupportedProtocolMethod: ProtocolMethod {
    let method: String

    // TODO - spec tag
    let requestConfig = RelayConfig(tag: 0, prompt: false, ttl: 86400)

    let responseConfig = RelayConfig(tag: 0, prompt: false, ttl: 86400)
}
