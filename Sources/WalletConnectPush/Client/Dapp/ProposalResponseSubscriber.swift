import Foundation
import Combine

class ProposalResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()
    var onResponse: ((_ id: RPCID, _ result: Result<PushResponseParams, PairError>) -> Void)?

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        subscribeForProposalErrors()
    }

    private func subscribeForProposalErrors() {
        let protocolMethod = PushProposeProtocolMethod()
        networkingInteractor.responseErrorSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: ResponseSubscriptionErrorPayload<PushRequestParams>) in
                guard let error = PairError(code: payload.error.code) else { return }
                onResponse?(payload.id, .failure(error))
            }.store(in: &publishers)
    }
}
