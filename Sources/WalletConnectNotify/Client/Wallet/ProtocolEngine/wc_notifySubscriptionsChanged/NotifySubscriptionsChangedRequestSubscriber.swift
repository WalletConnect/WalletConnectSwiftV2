import Foundation
import Combine

class NotifySubscriptionsChangedRequestSubscriber {
    private let keyserver: URL
    private let networkingInteractor: NetworkInteracting
    private let identityClient: IdentityClient
    private let logger: ConsoleLogging
    private let notifySubscriptionsUpdater: NotifySubsctiptionsUpdater
    private let notifySubscriptionsBuilder: NotifySubscriptionsBuilder

    init(
        keyserver: URL,
        networkingInteractor: NetworkInteracting,
        identityClient: IdentityClient,
        logger: ConsoleLogging,
        notifySubscriptionsUpdater: NotifySubsctiptionsUpdater,
        notifySubscriptionsBuilder: NotifySubscriptionsBuilder
    ) {
        self.keyserver = keyserver
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.identityClient = identityClient
        self.notifySubscriptionsUpdater = notifySubscriptionsUpdater
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

                let subscriptions = try await notifySubscriptionsBuilder.buildSubscriptions(jwtPayload.subscriptions)

                try await notifySubscriptionsUpdater.update(subscriptions: subscriptions, for: jwtPayload.account)

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
