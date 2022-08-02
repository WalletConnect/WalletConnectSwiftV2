import Combine
import Foundation
import WalletConnectUtils

actor AuthRequstSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()
    private let messageFormatter: SIWEMessageFormatter
    var onRequest: ((_ id: Int64, _ message: String)->())?

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         messageFormatter: SIWEMessageFormatter) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.messageFormatter = messageFormatter
    }

    private func subscribeForRequest() {
        networkingInteractor.requestPublisher.sink { [unowned self] subscriptionPayload in
            guard subscriptionPayload.request.method == "wc_authRequest" else { return }
            guard let authRequest = try? subscriptionPayload.request.params?.get(AuthRequestParams.self) else {
                logger.debug("Malformed auth request params")
                return
            }
            do {
                let message = try messageFormatter.formatMessage(from: authRequest)
                onRequest?(subscriptionPayload.request.id!.right!, message)
            } catch {
                logger.debug(error)
            }
        }.store(in: &publishers)
    }
}

struct SIWEMessageFormatter {
    func formatMessage(from request: AuthRequestParams) throws -> String {
        fatalError("not implemented")
    }
}
