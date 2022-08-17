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
    var onRequest: ((_ id: RPCID, _ result: Result<String, ErrorCode>) -> Void)?

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         messageFormatter: SIWEMessageFormatting,
         address: String?) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.address = address
        self.messageFormatter = messageFormatter
        subscribeForRequest()
    }

    private func subscribeForRequest() {
        guard let address = address else {return}
        networkingInteractor.requestPublisher.sink { [unowned self] subscriptionPayload in

            logger.debug("WalletRequestSubscriber: Received request")

            guard let requestId = subscriptionPayload.request.id, subscriptionPayload.request.method == "wc_authRequest"
            else { return }

            guard let authRequestParams = try? subscriptionPayload.request.params?.get(AuthRequestParams.self)
            else { self.onRequest?(requestId, .failure(.malformedRequestParams)); return }

            let message = messageFormatter.formatMessage(from: authRequestParams.payloadParams, address: address)

            onRequest?(requestId, .success(message))
        }.store(in: &publishers)
    }

}
