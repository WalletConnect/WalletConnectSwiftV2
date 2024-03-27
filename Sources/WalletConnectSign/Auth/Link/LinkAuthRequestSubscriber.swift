import Foundation
import Combine

class LinkAuthRequestSubscriber {
    private let logger: ConsoleLogging
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let envelopesDispatcher: LinkEnvelopesDispatcher

    var onRequest: (((request: AuthenticationRequest, context: VerifyContext?)) -> Void)?

    init(
        logger: ConsoleLogging,
        kms: KeyManagementServiceProtocol,
        envelopesDispatcher: LinkEnvelopesDispatcher
    ) {
        self.logger = logger
        self.kms = kms
        self.envelopesDispatcher = envelopesDispatcher
        subscribeForRequest()
    }

    private func subscribeForRequest() {

        envelopesDispatcher.requestSubscription(on: SessionAuthenticatedProtocolMethod().method)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionAuthenticateRequestParams>) in

                print(payload)
            }.store(in: &publishers)

    }

}
