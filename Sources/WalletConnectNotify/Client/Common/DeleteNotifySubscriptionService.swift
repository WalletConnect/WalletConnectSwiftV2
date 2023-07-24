import Foundation

class DeleteNotifySubscriptionService {
    enum Errors: Error {
        case notifySubscriptionNotFound
    }
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private let notifyStorage: NotifyStorage

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         notifyStorage: NotifyStorage) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.notifyStorage = notifyStorage
    }

    func delete(topic: String) async throws {
        let params = NotifyDeleteParams.userDisconnected
        logger.debug("Will delete notify subscription for reason: message: \(params.message) code: \(params.code), topic: \(topic)")
        guard let _ = notifyStorage.getSubscription(topic: topic)
        else { throw Errors.notifySubscriptionNotFound}
        let protocolMethod = NotifyDeleteProtocolMethod()
        try await notifyStorage.deleteSubscription(topic: topic)
        notifyStorage.deleteMessages(topic: topic)
        let request = RPCRequest(method: protocolMethod.method, params: params)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)

        networkingInteractor.unsubscribe(topic: topic)
        logger.debug("Subscription removed, topic: \(topic)")

        kms.deleteSymmetricKey(for: topic)
    }
}
