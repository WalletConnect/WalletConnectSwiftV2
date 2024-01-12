import Foundation
import Combine

class ProposalExpiryWatcher {

    private let sessionProposalExpirationPublisherSubject: PassthroughSubject<Session.Proposal, Never> = .init()
    private let historyService: HistoryService

    var sessionProposalExpirationPublisher: AnyPublisher<Session.Proposal, Never> {
        return sessionProposalExpirationPublisherSubject.eraseToAnyPublisher()
    }

    private let proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>
    private var checkTimer: Timer?

    internal init(
        proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>,
        historyService: HistoryService
    ) {
        self.proposalPayloadsStore = proposalPayloadsStore
        self.historyService = historyService
        setUpExpiryCheckTimer()
    }

    func setUpExpiryCheckTimer() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [unowned self] _ in
            checkForProposalsExpiry()
        }
    }

    func checkForProposalsExpiry() {
        let proposals = historyService.getPendingProposals()
        proposals.forEach { proposal in

            let proposal = proposal.proposal

            sessionProposalExpirationPublisherSubject.send(proposal)

            proposalPayloadsStore.delete(forKey: proposal.id)
        }
    }
}
