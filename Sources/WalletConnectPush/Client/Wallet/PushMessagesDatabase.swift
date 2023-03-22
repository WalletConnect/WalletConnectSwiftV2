
import Foundation
import WalletConnectUtils
import Combine

class PushMessagesDatabase {
    private let store: CodableStore<PushMessageRecord>

    init(store: CodableStore<PushMessageRecord>) {
        self.store = store
    }

    func getPushMessages(topic: String) -> [PushMessageRecord] {
        return store.getAll().filter{$0.topic == topic}
    }

    func deletePushMessages(topic: String) {
        let messagesKeys = getPushMessages(topic: topic).map{$0.id}
        store.delete(forKeys: messagesKeys)
    }

    func deletePushMessage(id: String) {
        store.delete(forKey: id)
    }

    func setPushMessageRecord(_ record: PushMessageRecord) {
        store.set(record, forKey: record.id)
    }

}

public struct PushMessageRecord: Codable, Equatable {
    public let id: String
    public let topic: String
    public let message: PushMessage
    public let publishedAt: Date
}
