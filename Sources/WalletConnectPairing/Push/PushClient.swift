import Foundation
import WalletConnectKMS
import WalletConnectUtils
import WalletConnectNetworking
import JSONRPC
import Combine

public class PushClient: Pairingable {
    public var requestPublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest), Never>()

    public var protocolMethod: ProtocolMethod

    public var proposalPublisher: AnyPublisher<(topic: String, request: RPCRequest), Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    private let pushProposer: PushProposer

    public let logger: ConsoleLogging

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         protocolMethod: ProtocolMethod,
         pushProposer: PushProposer) {
        self.logger = logger
        self.protocolMethod = protocolMethod
        self.pushProposer = pushProposer
    }

    public func propose(topic: String) async throws {
        try await pushProposer.request(topic: topic, params: AnyCodable(PushRequestParams()))
    }
}
