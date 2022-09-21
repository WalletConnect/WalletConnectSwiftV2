
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
    var pairingables = [Pairingable]()

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
    }

    func setPairingables(_ pairingables: [Pairingable]) {
        self.pairingables = pairingables
        let methods = pairingables.map{$0.protocolMethod}
        subscribeForRequests(methods: methods)

    }

    private func subscribeForRequests(methods: [ProtocolMethod]) {
        // TODO - spec tag
        let tag = 123456
        networkingInteractor.requestPublisher
            .sink { [unowned self] topic, request in
                guard let pairingable = pairingables
                    .first(where: { p in
                        p.protocolMethod.method == request.method
                    }) else {
                    Task { try await networkingInteractor.respondError(topic: topic, requestId: request.id!, tag: tag, reason: PairError.methodUnsupported) }
                    return
                }
                pairingable.requestPublisherSubject.send((topic: topic, request: request))

            }.store(in: &publishers)
    }

}
