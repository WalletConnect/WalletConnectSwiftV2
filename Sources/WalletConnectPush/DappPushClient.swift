import Foundation
import Combine
import WalletConnectUtils
public struct PushMessage: Codable {

}
public class DappPushClient {

    private let responsePublisherSubject = PassthroughSubject<(id: RPCID, result: Result<PushResponseParams, PairError>), Never>()

    public var responsePublisher: AnyPublisher<(id: RPCID, result: Result<PushResponseParams, PairError>), Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }

    public let logger: ConsoleLogging

    private let pushProposer: PushProposer
    private let proposalResponseSubscriber: ProposalResponseSubscriber

    init(logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         pushProposer: PushProposer,
         proposalResponseSubscriber: ProposalResponseSubscriber) {
        self.logger = logger
        self.pushProposer = pushProposer
        self.proposalResponseSubscriber = proposalResponseSubscriber
        setupSubscriptions()
    }

    public func request(account: Account, topic: String) async throws {
        try await pushProposer.request(topic: topic, params: PushRequestParams())
    }

    public func notify(topic: String, message: PushMessage) async throws {
        fatalError("not implemented")
    }

    public func getActiveSubscriptions() -> [PushSubscription] {
        fatalError("not implemented")
    }

    public func delete(topic: String) async throws {
        fatalError("not implemented")
    }

}

private extension DappPushClient {

    func setupSubscriptions() {
        proposalResponseSubscriber.onResponse = {[unowned self] (id, result) in
            responsePublisherSubject.send((id, result))
        }
    }
}
