import Foundation

struct SessionRequestProtocolMethod: ProtocolMethod {

    static let defaultTtl: Int = 300

    let method: String = "wc_sessionRequest"

    private let ttl: Int

    var requestConfig: RelayConfig {
        RelayConfig(tag: 1108, prompt: true, ttl: ttl)
    }

    var responseConfig: RelayConfig {
        RelayConfig(tag: 1109, prompt: false, ttl: ttl)
    }

    init(ttl: Int = Self.defaultTtl) {
        self.ttl = ttl
    }
}
