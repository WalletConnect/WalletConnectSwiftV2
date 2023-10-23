import Foundation
import Combine

class NotifyUpdateResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let notifyStorage: NotifyStorage
    private let nofityConfigProvider: NotifyConfigProvider

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         notifyConfigProvider: NotifyConfigProvider,
         notifyStorage: NotifyStorage
    ) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.notifyStorage = notifyStorage
        self.nofityConfigProvider = notifyConfigProvider
        subscribeForUpdateResponse()
    }

    // TODO: handle error response
}

private extension NotifyUpdateResponseSubscriber {
    enum Errors: Error {
        case subscriptionDoesNotExist
        case selectedScopeNotFound
    }

    func subscribeForUpdateResponse() {
        networkingInteractor.subscribeOnResponse(
            protocolMethod: NotifyUpdateProtocolMethod(),
            requestOfType: NotifyUpdatePayload.Wrapper.self,
            responseOfType: NotifyUpdateResponsePayload.Wrapper.self,
            errorHandler: logger
        ) { [unowned self] payload in

            let _ = try NotifyUpdateResponsePayload.decodeAndVerify(from: payload.response)

            logger.debug("Received Notify Update response")
        }
    }
}
