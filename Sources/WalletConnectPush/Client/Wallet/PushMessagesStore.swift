
import Foundation
import WalletConnectUtils
import Combine

class PushMessagesStore {
    private let history: RPCHistory

    init(history: RPCHistory) {
        self.history = history
    }

    func getPushMessages(topic: String) -> [PushMessage] {
        history.getAll(of: PushMessage.self, topic: topic)
    }

    func deletePushMessages(topic: String) {
        history.deleteAll(forTopic: topic)
    }

}
