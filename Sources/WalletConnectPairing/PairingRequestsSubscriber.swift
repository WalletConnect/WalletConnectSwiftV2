import Foundation
import Combine
import WalletConnectUtils
import WalletConnectNetworking
import JSONRPC

public class PairingRequestsSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let pairingStorage: PairingStorage
    private var publishers = Set<AnyCancellable>()

    init(networkingInteractor: NetworkInteracting, pairingStorage: PairingStorage, logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.pairingStorage = pairingStorage
    }

    func subscribeForRequest(_ protocolMethod: ProtocolMethod) -> AnyPublisher<(topic: String, request: RPCRequest), Never> {
        let publisherSubject = PassthroughSubject<(topic: String, request: RPCRequest), Never>()
        networkingInteractor.requestPublisher
            .sink { [unowned self] topic, request in
                if request.method != protocolMethod.method {
                    Task(priority: .high) {
                        // TODO - spec tag
                        try await networkingInteractor.respondError(topic: topic, requestId: request.id!, protocolMethod: protocolMethod, reason: PairError.methodUnsupported)
                    }
                } else {
                    publisherSubject.send((topic, request))
                }

            }.store(in: &publishers)

        return publisherSubject.eraseToAnyPublisher()
    }

}
