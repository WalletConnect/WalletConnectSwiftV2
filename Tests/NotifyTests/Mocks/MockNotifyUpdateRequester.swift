
import Foundation
@testable import WalletConnectNotify


class MockNotifyUpdateRequester: NotifyUpdateRequesting {
    var updatedTopics: [String] = []
    var completionHandler: (() -> Void)?

    func update(topic: String, scope: Set<String>) async throws {
        updatedTopics.append(topic)
        completionHandler?()
    }
}

