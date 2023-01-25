
import Foundation
import WalletConnectUtils

class PushMessagesProvider {
    private let history: RPCHistory

    init(history: RPCHistory) {
        self.history = history
    }

    public func getMessageHistory(topic: String) -> [PushMessage] {
        history.getAll(of: PushMessage.self, topic: topic)
    }
}
