import Foundation
import Combine
import WalletConnectUtils

public class DappPushClient {

    private let responsePublisherSubject = PassthroughSubject<(id: RPCID, result: Result<PushSubscription, PairError>), Never>()

    public var responsePublisher: AnyPublisher<(id: RPCID, result: Result<PushSubscription, PairError>), Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }

    public let logger: ConsoleLogging

    private let pushProposer: PushProposer
    private let pushMessageSender: PushMessageSender
    private let proposalResponseSubscriber: ProposalResponseSubscriber

    init(logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         pushProposer: PushProposer,
         proposalResponseSubscriber: ProposalResponseSubscriber,
         pushMessageSender: PushMessageSender) {
        self.logger = logger
        self.pushProposer = pushProposer
        self.proposalResponseSubscriber = proposalResponseSubscriber
        self.pushMessageSender = pushMessageSender
        setupSubscriptions()
    }

    public func request(account: Account, topic: String) async throws {
        try await pushProposer.request(topic: topic, account: account)
    }

    public func notify(topic: String, message: PushMessage) async throws {
        try await pushMessageSender.request(topic: topic, message: message)
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
