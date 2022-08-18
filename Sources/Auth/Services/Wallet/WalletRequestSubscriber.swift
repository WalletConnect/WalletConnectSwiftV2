import Combine
import Foundation
import WalletConnectUtils
import JSONRPC

class WalletRequestSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let address: String?
    private var publishers = [AnyCancellable]()
    private let messageFormatter: SIWEMessageFormatting
    var onRequest: ((_ id: RPCID, _ message: String) -> Void)?

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         messageFormatter: SIWEMessageFormatting,
         address: String?) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.address = address
        self.messageFormatter = messageFormatter
        if address != nil {
            subscribeForRequest()
        }
    }

    private func subscribeForRequest() {
        print("adasdadsadsadsadsadsdscaadsdasdasdsdsds")
        networkingInteractor.requestPublisher.sink { [unowned self] subscriptionPayload in
            guard
                let requestId = subscriptionPayload.request.id,
                subscriptionPayload.request.method == "wc_authRequest" else { return }

            do {
                guard let authRequestParams = try subscriptionPayload.request.params?.get(AuthRequestParams.self) else { return logger.debug("Malformed auth request params")
                }

                let message = messageFormatter.formatMessage(
                    from: authRequestParams.payloadParams,
                    address: address!
                )

                onRequest?(requestId, message)
            } catch {
                logger.debug(error)
            }
        }.store(in: &publishers)
    }

}
