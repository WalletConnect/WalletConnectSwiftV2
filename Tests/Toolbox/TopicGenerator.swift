@testable import WalletConnectUtils

public final class TopicGenerator {

    let topic: String

    init(topic: String = String.generateTopic()) {
        self.topic = topic
    }

    func getTopic() -> String {
        return topic
    }
}
