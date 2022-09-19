import Foundation
import WalletConnectKMS
import WalletConnectUtils
import WalletConnectNetworking
import Combine

struct ProposalParams: Codable {}

public class PushClient: Paringable {

    public var protocolMethod: ProtocolMethod
    public var proposalPublisher: AnyPublisher<String, Never> {
        proposalPublisherSubject.eraseToAnyPublisher()
    }
    private let proposalPublisherSubject = PassthroughSubject<String, Never>()

    public var pairingRequestSubscriber: PairingRequestSubscriber! {
        didSet {
            handleProposal()
        }
    }

    public var pairingRequester: PairingRequester!

    public let logger: ConsoleLogging

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol) {
        self.logger = logger

        protocolMethod = PushProtocolMethod.propose
    }

    func handleProposal() {
        pairingRequestSubscriber.onRequest = { [unowned self] _ in
            logger.debug("Push: received proposal")
            proposalPublisherSubject.send("done")
        }
    }

    public func propose(topic: String) async throws {
        try await pairingRequester.request(topic: topic, params: AnyCodable(PushRequestParams()))
    }
}
