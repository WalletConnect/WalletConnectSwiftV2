import Foundation
import Combine

class NotifySubscribeResponseSubscriber {
    enum Errors: Error {
        case couldNotCreateSubscription
    }

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let notifyStorage: NotifyStorage
    private let groupKeychainStorage: KeychainStorageProtocol
    private let dappsMetadataStore: CodableStore<AppMetadata>
    private let notifyConfigProvider: NotifyConfigProvider

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         groupKeychainStorage: KeychainStorageProtocol,
         notifyStorage: NotifyStorage,
         dappsMetadataStore: CodableStore<AppMetadata>,
         notifyConfigProvider: NotifyConfigProvider
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.groupKeychainStorage = groupKeychainStorage
        self.notifyStorage = notifyStorage
        self.dappsMetadataStore = dappsMetadataStore
        self.notifyConfigProvider = notifyConfigProvider
        subscribeForSubscriptionResponse()
    }

    private func subscribeForSubscriptionResponse() {
        networkingInteractor.subscribeOnResponse(
            protocolMethod: NotifySubscribeProtocolMethod(),
            requestOfType: NotifySubscriptionPayload.Wrapper.self,
            responseOfType: NotifySubscriptionResponsePayload.Wrapper.self,
            errorHandler: logger
        ) { [unowned self] payload in
            logger.debug("Received Notify Subscribe response")

            let _ = try NotifySubscriptionResponsePayload.decodeAndVerify(from: payload.response)

            logger.debug("NotifySubscribeResponseSubscriber: unsubscribing from response topic: \(payload.topic)")

            networkingInteractor.unsubscribe(topic: payload.topic)
        }
    }
}
