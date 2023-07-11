import Foundation

class DeletePushSubscriptionService {
    enum Errors: Error {
        case pushSubscriptionNotFound
    }
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private let pushStorage: PushStorage

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         pushStorage: PushStorage) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.pushStorage = pushStorage
    }

    func delete(topic: String) async throws {
        let params = PushDeleteParams.userDisconnected
        logger.debug("Will delete push subscription for reason: message: \(params.message) code: \(params.code), topic: \(topic)")
        guard let _ = pushStorage.getSubscription(topic: topic)
        else { throw Errors.pushSubscriptionNotFound}
        let protocolMethod = PushDeleteProtocolMethod()
        try await pushStorage.deleteSubscription(topic: topic)
        pushStorage.deleteMessages(topic: topic)
        let request = RPCRequest(method: protocolMethod.method, params: params)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)

        networkingInteractor.unsubscribe(topic: topic)
        logger.debug("Subscription removed, topic: \(topic)")

        kms.deleteSymmetricKey(for: topic)
    }
}
