import Foundation

public struct Thread: Codable, Equatable {
    public let topic: String
    public let selfAccount: Account
    public let peerAccount: Account
    public let symKey: String
}

extension Thread: SyncObject {

    public var syncId: String {
        return topic
    }
}
