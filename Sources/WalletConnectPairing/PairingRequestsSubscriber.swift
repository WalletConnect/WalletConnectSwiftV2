import Foundation
import Combine
import WalletConnectUtils
import WalletConnectNetworking

public class PairingRequestsSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let pairingStorage: PairingStorage
    private var publishers = Set<AnyCancellable>()

    init(networkingInteractor: NetworkInteracting, pairingStorage: PairingStorage, logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.pairingStorage = pairingStorage
    }

    func subscribeForRequest(_ protocolMethod: ProtocolMethod) {
        networkingInteractor.requestPublisher
            // Pairing requests only
            .filter { [unowned self] payload in
                return pairingStorage.hasPairing(forTopic: payload.topic)
            }
            // Wrong method
            .filter { payload in
                return payload.request.method != protocolMethod.method
            }
            // Respond error
            .sink { [unowned self] topic, request in
                Task(priority: .high) {
                    // TODO - spec tag
                    try await networkingInteractor.respondError(topic: topic, requestId: request.id!, protocolMethod: protocolMethod, reason: PairError.methodUnsupported)
                }

            }.store(in: &publishers)
    }

}
