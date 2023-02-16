import Foundation
import WalletConnectKMS
import WalletConnectUtils

class DeletePushSubscriptionService {
    enum Errors: Error {
        case pushSubscriptionNotFound
    }
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private let pushSubscriptionStore: CodableStore<PushSubscription>
    private let pushMessagesDatabase: PushMessagesDatabase?
    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         pushSubscriptionStore: CodableStore<PushSubscription>,
         pushMessagesDatabase: PushMessagesDatabase?) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.pushMessagesDatabase = pushMessagesDatabase
        self.pushSubscriptionStore = pushSubscriptionStore
    }

    func delete(topic: String) async throws {
        guard let _ = try? pushSubscriptionStore.get(key: topic)
        else { throw Errors.pushSubscriptionNotFound}
        let protocolMethod = PushDeleteProtocolMethod()
        let params = PushDeleteParams.userDisconnected
        logger.debug("Will delete push subscription for reason: message: \(params.message) code: \(params.code)")
        pushSubscriptionStore.delete(forKey: topic)
        pushMessagesDatabase?.deletePushMessages(topic: topic)
        let request = RPCRequest(method: protocolMethod.method, params: params)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)

        networkingInteractor.unsubscribe(topic: topic)
        logger.debug("Subscription removed, topic: \(topic)")

        kms.deleteSymmetricKey(for: topic)
    }
}
