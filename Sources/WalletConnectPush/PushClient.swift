import Foundation
import Combine

public class PushClient {

    private var publishers = Set<AnyCancellable>()

    private let requestPublisherSubject = PassthroughSubject<(topic: String, params: PushRequestParams), Never>()
    private let responsePublisherSubject = PassthroughSubject<(id: RPCID, result: Result<PushResponseParams, PairError>), Never>()

    public var proposalPublisher: AnyPublisher<(topic: String, params: PushRequestParams), Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }
    public var responsePublisher: AnyPublisher<(id: RPCID, result: Result<PushResponseParams, PairError>), Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }

    public let logger: ConsoleLogging

    private let pushProposer: PushProposer
    private let pairingRegisterer: PairingRegisterer
    private let registerService: PushRegisterService
    private let proposalResponseSubscriber: ProposalResponseSubscriber

    init(logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         pushProposer: PushProposer,
         registerService: PushRegisterService,
         proposalResponseSubscriber: ProposalResponseSubscriber,
         pairingRegisterer: PairingRegisterer) {
        self.logger = logger
        self.pushProposer = pushProposer
        self.pairingRegisterer = pairingRegisterer
        self.registerService = registerService
        self.proposalResponseSubscriber = proposalResponseSubscriber
        setupSubscriptions()
    }

    public func propose(topic: String) async throws {
        try await pushProposer.request(topic: topic, params: PushRequestParams())
    }

    public func register(deviceToken: Data) async throws {
        try await registerService.register(deviceToken: deviceToken)
    }
}

private extension PushClient {

    func setupSubscriptions() {
        let protocolMethod = PushProposeProtocolMethod()

        pairingRegisterer.register(method: protocolMethod)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<PushRequestParams>) in
                requestPublisherSubject.send((topic: payload.topic, params: payload.request))
        }.store(in: &publishers)

        proposalResponseSubscriber.onResponse = {[unowned self] (id, result) in
            responsePublisherSubject.send((id, result))
        }
    }
}
