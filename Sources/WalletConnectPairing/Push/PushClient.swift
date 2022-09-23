import Foundation
import JSONRPC
import Combine
import WalletConnectKMS
import WalletConnectUtils
import WalletConnectNetworking

public class PushClient {

    private var publishers = Set<AnyCancellable>()

    let requestPublisherSubject = PassthroughSubject<(topic: String, params: PushRequestParams), Never>()

    var proposalPublisher: AnyPublisher<(topic: String, params: PushRequestParams), Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    public let logger: ConsoleLogging

    private let pushProposer: PushProposer
    private let networkInteractor: NetworkInteracting
    private let pairingRegisterer: PairingRegisterer

    init(networkInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         pushProposer: PushProposer,
         pairingRegisterer: PairingRegisterer) {
        self.networkInteractor = networkInteractor
        self.logger = logger
        self.pushProposer = pushProposer
        self.pairingRegisterer = pairingRegisterer

        setupPairingSubscriptions()
    }

    public func propose(topic: String) async throws {
        try await pushProposer.request(topic: topic, params: AnyCodable(PushRequestParams()))
    }
}

private extension PushClient {

    func setupPairingSubscriptions() {
        pairingRegisterer.register(method: PushProtocolMethod.propose)

        networkInteractor.responseErrorSubscription(on: PushProtocolMethod.propose)
            .sink { [unowned self] (payload: ResponseSubscriptionErrorPayload<PushRequestParams>) in
                logger.error(payload.error.localizedDescription)
            }.store(in: &publishers)

        networkInteractor.requestSubscription(on: PushProtocolMethod.propose)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<PushRequestParams>) in
                requestPublisherSubject.send((payload.topic, payload.request))
            }.store(in: &publishers)
    }
}
