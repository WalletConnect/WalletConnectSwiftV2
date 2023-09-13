import Foundation
import Combine

class NotifySubscriptionsChangedRequestSubscriber {
    private let keyserver: URL
    private let networkingInteractor: NetworkInteracting
    private let identityClient: IdentityClient
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private let groupKeychainStorage: KeychainStorageProtocol
    private let notifyStorage: NotifyStorage
    private let notifySubscriptionsBuilder: NotifySubscriptionsBuilder
    
    init(
        keyserver: URL,
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        identityClient: IdentityClient,
        logger: ConsoleLogging,
        groupKeychainStorage: KeychainStorageProtocol,
        notifyStorage: NotifyStorage,
        notifySubscriptionsBuilder: NotifySubscriptionsBuilder
    ) {
        self.keyserver = keyserver
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.identityClient = identityClient
        self.groupKeychainStorage = groupKeychainStorage
        self.notifyStorage = notifyStorage
        self.notifySubscriptionsBuilder = notifySubscriptionsBuilder
        subscribeForNofifyChangedRequests()
    }


    private func subscribeForNofifyChangedRequests() {
        networkingInteractor.subscribeOnRequest(
            protocolMethod: NotifySubscriptionsChangedProtocolMethod(),
            requestOfType: NotifySubscriptionsChangedRequestPayload.Wrapper.self,
            errorHandler: logger) { [unowned self] payload in
                logger.debug("Received Subscriptions Changed Request")

                let (jwtPayload, _) = try NotifySubscriptionsChangedRequestPayload.decodeAndVerify(from: payload.request)
                let account = jwtPayload.account

                // todo varify signature with notify server diddoc authentication key

                let oldSubscriptions = notifyStorage.getSubscriptions()
                let newSubscriptions = try await notifySubscriptionsBuilder.buildSubscriptions(jwtPayload.subscriptions)
                logger.debug("number of subscriptions: \(newSubscriptions.count)")

                guard newSubscriptions != oldSubscriptions else {return}

                notifyStorage.replaceAllSubscriptions(newSubscriptions, account: account)

                for subscription in newSubscriptions {
                    let symKey = try SymmetricKey(hex: subscription.symKey)
                    try groupKeychainStorage.add(symKey, forKey: subscription.topic)
                    try kms.setSymmetricKey(symKey, for: subscription.topic)
                }

                let topics = newSubscriptions.map { $0.topic }

                try await networkingInteractor.batchSubscribe(topics: topics)

                try Task.checkCancellation()

                var logProperties = ["rpcId": payload.id.string]
                for (index, subscription) in newSubscriptions.enumerated() {
                    let key = "subscription_\(index + 1)"
                    logProperties[key] = subscription.topic
                }

                logger.debug("Updated Subscriptions by Subscriptions Changed Request", properties: logProperties)

                try await respond(topic: payload.topic, account: jwtPayload.account, rpcId: payload.id, notifyServerAuthenticationKey: jwtPayload.notifyServerAuthenticationKey)
            }
    }

    private func respond(topic: String, account: Account, rpcId: RPCID, notifyServerAuthenticationKey: DIDKey) async throws {

        let receiptPayload = NotifySubscriptionsChangedResponsePayload(account: account, keyserver: keyserver, notifyServerAuthenticationKey: notifyServerAuthenticationKey)

        let wrapper = try identityClient.signAndCreateWrapper(
            payload: receiptPayload,
            account: account
        )

        let response = RPCResponse(id: rpcId, result: wrapper)
        try await networkingInteractor.respond(
            topic: topic,
            response: response,
            protocolMethod: NotifySubscriptionsChangedProtocolMethod()
        )

        let logProperties = ["rpcId": rpcId.string]
        logger.debug("Responded for Subscriptions Changed Request", properties: logProperties)
    }

}
