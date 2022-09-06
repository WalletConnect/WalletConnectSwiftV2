import Foundation
import WalletConnectNetworking
import JSONRPC

class PingService {
    private let pairingStorage: WCPairingStorage
    private let networkingInteractor: NetworkInteracting

    init(pairingStorage: WCPairingStorage, networkingInteractor: NetworkInteracting) {
        self.pairingStorage = pairingStorage
        self.networkingInteractor = networkingInteractor
    }

    func ping(topic: String) async throws {
        guard pairingStorage.hasPairing(forTopic: topic) else { return }
        let request = RPCRequest(method: PairingProtocolMethod.ping.rawValue, params: PairingPingParams())
        try await networkingInteractor.request(request, topic: topic, tag: PairingProtocolMethod.ping.requestTag)
    }
}


import Combine
import WalletConnectUtils

class PingResponder {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        subscribePingRequests()
    }

    func subscribePingRequests() {
        networkingInteractor.requestSubscription(on: PairingProtocolMethod.ping)
            .sink { [unowned self]  (payload: RequestSubscriptionPayload<PairingPingParams>) in
                logger.debug("Responding for pairing ping")
                Task {
                    try? await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, tag: PairingProtocolMethod.ping.responseTag)
                }
            }
            .store(in: &publishers)
    }
}

class PingResponseSubscriber {

}
