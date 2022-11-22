import Foundation
import Combine
import WalletConnectNetworking

public class WalletPushClient {

    private var publishers = Set<AnyCancellable>()

    private let requestPublisherSubject = PassthroughSubject<(topic: String, params: PushRequestParams), Never>()

    public var proposalPublisher: AnyPublisher<(topic: String, params: PushRequestParams), Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    public let logger: ConsoleLogging

    private let pairingRegisterer: PairingRegisterer
    private let registerService: PushRegisterService

    init(logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         registerService: PushRegisterService,
         pairingRegisterer: PairingRegisterer) {
        self.logger = logger
        self.pairingRegisterer = pairingRegisterer
        self.registerService = registerService
        setupSubscriptions()
    }


    public func approve(proposalId: String) async throws {
        fatalError("not implemented")
    }

    public func reject(proposalId: String, reason: Reason) async throws {
        fatalError("not implemented")
    }

    public func getActiveSubscriptions() -> [PushSubscription] {
        fatalError("not implemented")
    }

    public func delete(topic: String) async throws {
        fatalError("not implemented")
    }

    public func decryptMessage(topic: String, ciphertext: String) -> String {
        fatalError("not implemented")
    }


    public func register(deviceToken: Data) async throws {
        try await registerService.register(deviceToken: deviceToken)
    }
}

private extension WalletPushClient {

    func setupSubscriptions() {
        let protocolMethod = PushProposeProtocolMethod()

        pairingRegisterer.register(method: protocolMethod)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<PushRequestParams>) in
                requestPublisherSubject.send((topic: payload.topic, params: payload.request))
        }.store(in: &publishers)
    }
}
