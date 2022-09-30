import Foundation
import Combine
import WalletConnectNetworking
import WalletConnectUtils

final class AppPairActivationService {
    private let networkInteractor: NetworkInteracting
    private let pairingStorage: PairingStorage
    private let history: RPCHistory
    private let logger: ConsoleLogging

    private var publishers = Set<AnyCancellable>()

    init(
        networkInteractor: NetworkInteracting,
        pairingStorage: PairingStorage,
        history: RPCHistory,
        logger: ConsoleLogging
    ) {
        self.networkInteractor = networkInteractor
        self.pairingStorage = pairingStorage
        self.history = history
        self.logger = logger
    }

    func activate(on method: ProtocolMethod) {
        networkInteractor.responseSubscription(on: method)
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<AnyCodable, AnyCodable>) in
                guard var pairing = pairingStorage.getPairing(forTopic: payload.topic) else {
                    return logger.error("Pairing not found for topic: \(payload.topic)")
                }
                if !pairing.active {
                    pairing.activate()
                } else {
                    try? pairing.updateExpiry()
                }
            }.store(in: &publishers)
    }
}
