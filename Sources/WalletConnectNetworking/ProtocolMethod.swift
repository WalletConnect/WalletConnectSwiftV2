import Foundation

public protocol ProtocolMethod {
    var method: String { get }
    var request: RelayConfigrable { get }
    var response: RelayConfigrable { get }
}

public struct RelayConfigrable {
    var tag: Int
    var prompt: Bool
    
    public init(tag: Int, prompt: Bool) {
        self.tag = tag
        self.prompt = prompt
    }
}
