import Foundation

struct PushProposeProtocolMethod: ProtocolMethod {
    let method: String = "wc_pushPropose"

    let requestConfig: RelayConfig = RelayConfig(tag: 111, prompt: true, ttl: 300)

    let responseConfig: RelayConfig = RelayConfig(tag: 112, prompt: true, ttl: 300)
}

public struct PushRequestParams: Codable {}

public struct PushResponseParams: Codable, Equatable {}
