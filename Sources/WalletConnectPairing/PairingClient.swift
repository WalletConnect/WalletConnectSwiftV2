import Foundation
import WalletConnectUtils
import WalletConnectRelay
import WalletConnectNetworking
import Combine

public class PairingClient {
    private let walletPairService: WalletPairService
    private let appPairService: AppPairService
    public let socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>
    let logger: ConsoleLogging
    private let networkingInteractor: NetworkInteracting

    init(appPairService: AppPairService,
         networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         walletPairService: WalletPairService,
         socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>
    ) {
        self.appPairService = appPairService
        self.walletPairService = walletPairService
        self.networkingInteractor = networkingInteractor
        self.socketConnectionStatusPublisher = socketConnectionStatusPublisher
        self.logger = logger
    }
    /// For wallet to establish a pairing and receive an authentication request
    /// Wallet should call this function in order to accept peer's pairing proposal and be able to subscribe for future authentication request.
    /// - Parameter uri: Pairing URI that is commonly presented as a QR code by a dapp or delivered with universal linking.
    ///
    /// Throws Error:
    /// - When URI is invalid format or missing params
    /// - When topic is already in use
    public func pair(uri: WalletConnectURI) async throws {
        try await walletPairService.pair(uri)
    }

    public func create()  async throws -> WalletConnectURI {
        return try await appPairService.create()
    }

    public func configureProtocols(with paringables: [Pairingable]) {

    }
}

import Foundation
import Combine
import JSONRPC
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectNetworking


public class PairingRequestsSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    var onRequest: ((RequestSubscriptionPayload<AnyCodable>) -> Void)?
    let protocolMethod: ProtocolMethod
    var pairingables = [Pairingable]()

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         protocolMethod: ProtocolMethod) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.protocolMethod = protocolMethod
    }

    func setPairingables(_ pairingables: [Pairingable]) {
        self.pairingables = pairingables
        let methods = pairingables.map{$0.protocolMethod}
        subscribeForRequests(methods: methods)

    }

    private func subscribeForRequests(methods: [ProtocolMethod]) {
        // TODO - spec tag
        let tag = 123456
        networkingInteractor.requestSubscription(on: methods)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<RPCRequest>) in
                guard let pairingable = pairingables
                    .first(where: { p in
                        p.protocolMethod.method == payload.request.method
                    }) else {
                    Task { try await networkingInteractor.respondError(topic: payload.topic, requestId: payload.id, tag: tag, reason: PairError.methodUnsupported) }
                    return
                }
                pairingable.requestPublisherSubject.send((topic: payload.topic, request: payload.request))

            }.store(in: &publishers)
    }

}
public enum PairError: Codable, Equatable, Error, Reason {
    case methodUnsupported

    public var code: Int {
        //TODO - spec code
        return 44444
    }

    //TODO - spec message
    public var message: String {
        return "Method Unsupported"
    }

}
