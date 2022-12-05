import Foundation
import Combine
import WalletConnectNetworking
import WalletConnectPairing
import WalletConnectEcho

public class WalletPushClient {

    private var publishers = Set<AnyCancellable>()

    private let requestPublisherSubject = PassthroughSubject<(id: RPCID, metadata: AppMetadata), Never>()

    public var requestPublisher: AnyPublisher<(id: RPCID, metadata: AppMetadata), Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    public let logger: ConsoleLogging

    private let pairingRegisterer: PairingRegisterer
    private let echoRegisterer: EchoCLient
    private let proposeResponder: ProposeResponder

    init(logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         registerService: PushRegisterService,
         pairingRegisterer: PairingRegisterer,
         proposeResponder: ProposeResponder) {
        self.logger = logger
        self.pairingRegisterer = pairingRegisterer
        self.registerService = registerService
        self.proposeResponder = proposeResponder
        setupSubscriptions()
    }


    public func approve(id: RPCID) async throws {
        try await proposeResponder.respond(requestId: id)
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
                requestPublisherSubject.send((id: payload.id, metadata: payload.request.metadata))
        }.store(in: &publishers)
    }
}
