import Foundation
import Combine

class NotifyUpdateResponseSubscriber {
    
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging

    init(networkingInteractor: NetworkInteracting, logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger

        subscribeForUpdateResponse()
    }

    // TODO: handle error response
}

private extension NotifyUpdateResponseSubscriber {

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
