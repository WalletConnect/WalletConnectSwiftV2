import Foundation
import JSONRPC
import Combine
import WalletConnectKMS
import WalletConnectUtils
import WalletConnectNetworking
import WalletConnectPairing

public class PushClient {

    private var publishers = Set<AnyCancellable>()

    let requestPublisherSubject = PassthroughSubject<(topic: String, params: PushRequestParams), Never>()

    public var proposalPublisher: AnyPublisher<(topic: String, params: PushRequestParams), Never> {
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
        let protocolMethod = PushProposeProtocolMethod()

        pairingRegisterer.register(method: protocolMethod)
            .sink { [unowned self] (topic, request) in
                let params = try! request.params!.get(PushRequestParams.self)
                requestPublisherSubject.send((topic: topic, params: params))
        }.store(in: &publishers)

        networkInteractor.responseErrorSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: ResponseSubscriptionErrorPayload<PushRequestParams>) in
                logger.error(payload.error.localizedDescription)
            }.store(in: &publishers)

    }
}
