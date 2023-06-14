import Foundation

public struct Thread: Codable, Equatable {
    public let topic: String
    public let selfAccount: Account
    public let peerAccount: Account
    public let symKey: String
}

extension Thread: DatabaseObject {

    public var databaseId: String {
        return topic
    }
}
