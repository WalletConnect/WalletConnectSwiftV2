
import Foundation
@testable import Chat

class NetworkingInteractorMock: NetworkInteracting {
    private(set) var subscriptions: [String] = []

    func subscribe(topic: String) async throws {
        subscriptions.append(topic)
    }
    
    func didSubscribe(to topic: String) -> Bool {
        subscriptions.contains { $0 == topic }
    }
}
