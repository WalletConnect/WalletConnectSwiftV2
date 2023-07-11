import Foundation

public struct HistoryRecord<Object: Codable> {
    public let id: RPCID
    public let object: Object

    public init(id: RPCID, object: Object) {
        self.id = id
        self.object = object
    }
}
