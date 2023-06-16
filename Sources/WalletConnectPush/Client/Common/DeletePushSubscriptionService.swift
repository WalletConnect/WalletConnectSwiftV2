import Foundation

class DeletePushSubscriptionService {
    enum Errors: Error {
        case pushSubscriptionNotFound
    }
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private let pushSubscriptionStore: SyncStore<PushSubscription>
    private let pushMessagesDatabase: PushMessagesDatabase?
    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         pushSubscriptionStore: SyncStore<PushSubscription>,
         pushMessagesDatabase: PushMessagesDatabase?) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.pushMessagesDatabase = pushMessagesDatabase
        self.pushSubscriptionStore = pushSubscriptionStore
    }

    func delete(topic: String) async throws {
        let params = PushDeleteParams.userDisconnected
        logger.debug("Will delete push subscription for reason: message: \(params.message) code: \(params.code), topic: \(topic)")
        guard let _ = pushSubscriptionStore.get(for: topic)
        else { throw Errors.pushSubscriptionNotFound}
        let protocolMethod = PushDeleteProtocolMethod()
        try await pushSubscriptionStore.delete(id: topic)
        pushMessagesDatabase?.deletePushMessages(topic: topic)
        let request = RPCRequest(method: protocolMethod.method, params: params)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)

        networkingInteractor.unsubscribe(topic: topic)
        logger.debug("Subscription removed, topic: \(topic)")

        kms.deleteSymmetricKey(for: topic)
    }
}
