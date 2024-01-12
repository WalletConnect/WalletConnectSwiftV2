import Foundation
import Combine

class ProposalExpiryWatcher {

    private let sessionProposalExpirationPublisherSubject: PassthroughSubject<SessionProposal, Never> = .init()

    var sessionProposalExpirationPublisher: AnyPublisher<SessionProposal, Never> {
        return sessionProposalExpirationPublisherSubject.eraseToAnyPublisher()
    }

    private let proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>
    private var checkTimer: Timer?

    internal init(proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>) {
        self.proposalPayloadsStore = proposalPayloadsStore
    }

    func setUpExpiryCheckTimer() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [unowned self] _ in
            checkForProposalsExpiry()
        }
    }

    func checkForProposalsExpiry() {
        proposalPayloadsStore.getAll().forEach { payload in
            sessionProposalExpirationPublisherSubject.send(payload.request)
            proposalPayloadsStore.delete(forKey: payload.request.proposer.publicKey)
        }
    }
}
