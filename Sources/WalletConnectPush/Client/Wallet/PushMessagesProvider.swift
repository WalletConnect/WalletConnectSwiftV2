
import Foundation
import WalletConnectUtils
import Combine

class PushMessagesProvider {
    private let history: RPCHistory

    init(history: RPCHistory) {
        self.history = history
    }

    public func getMessageHistory(topic: String) -> [PushMessage] {
        history.getAll(of: PushMessage.self, topic: topic)
    }

}
