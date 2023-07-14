import Foundation

public struct RegisterPayload: Codable {
    public let tags: [String]
    public let relayUrl: String

    public init(tags: [String], relayUrl: String) {
        self.tags = tags
        self.relayUrl = relayUrl
    }
}
