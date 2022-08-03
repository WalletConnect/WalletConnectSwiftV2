import Combine
import Foundation
import WalletConnectUtils
import JSONRPC

class AuthRespondSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let rpcHistory: RPCHistory
    private var publishers = [AnyCancellable]()
    var onResponse: ((_ id: RPCID, _ cacao: Cacao)->Void)?

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         rpcHistory: RPCHistory) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.rpcHistory = rpcHistory
        subscribeForResponse()
    }

    private func subscribeForResponse() {
        networkingInteractor.responsePublisher.sink { [unowned self] response in
            guard let request = rpcHistory.get(recordId: response.id!)?.request,
                  request.method == "wc_authRequest" else { return }

            guard let cacao = try? response.result?.get(Cacao.self) else {
                logger.debug("Malformed auth response params")
                return
            }
            do {
                try CacaoSignatureVerifier().verifySignature(cacao)
                onResponse?(response.id!, cacao)
            } catch {
                logger.debug("Received response with invalid signature")
            }
        }.store(in: &publishers)
    }
}

