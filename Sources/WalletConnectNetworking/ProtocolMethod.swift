import Foundation

public protocol ProtocolMethod {
    var method: String { get }
    var requestConfig: RelayConfig { get }
    var responseConfig: RelayConfig { get }
}

public struct RelayConfig {
    let tag: Int
    let prompt: Bool
    let ttl: Int

    public init(tag: Int, prompt: Bool, ttl: Int) {
        self.tag = tag
        self.prompt = prompt
        self.ttl = ttl
    }
}
