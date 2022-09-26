import Foundation

public protocol ProtocolMethod {
    var method: String { get }
    var request: RelayConfig { get }
    var response: RelayConfig { get }
}

public struct RelayConfig {
    var tag: Int
    var prompt: Bool
    
    public init(tag: Int, prompt: Bool) {
        self.tag = tag
        self.prompt = prompt
    }
}
