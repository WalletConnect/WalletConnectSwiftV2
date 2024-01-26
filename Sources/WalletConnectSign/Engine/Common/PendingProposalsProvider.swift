import Foundation
import Combine

class PendingProposalsProvider {

    private let proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>
    private let verifyContextStore: CodableStore<VerifyContext>
    private var publishers = Set<AnyCancellable>()
    private let pendingProposalsPublisherSubject = CurrentValueSubject<[(proposal: Session.Proposal, context: VerifyContext?)], Never>([])

    var pendingProposalsPublisher: AnyPublisher<[(proposal: Session.Proposal, context: VerifyContext?)], Never> {
        return pendingProposalsPublisherSubject.eraseToAnyPublisher()
    }

    internal init(
        proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>,
        verifyContextStore: CodableStore<VerifyContext>)
    {
        self.proposalPayloadsStore = proposalPayloadsStore
        self.verifyContextStore = verifyContextStore
        updatePendingProposals()
        setUpPendingProposalsPublisher()
    }

    private func updatePendingProposals() {
        let proposalsWithVerifyContext = getPendingProposals()
        pendingProposalsPublisherSubject.send(proposalsWithVerifyContext)
    }

    func setUpPendingProposalsPublisher() {
        proposalPayloadsStore.storeUpdatePublisher.sink { [unowned self] _ in
            updatePendingProposals()
        }.store(in: &publishers)
    }

    private func getPendingProposals() -> [(proposal: Session.Proposal, context: VerifyContext?)] {
        let proposals = proposalPayloadsStore.getAll()
        return proposals.map { ($0.request.publicRepresentation(pairingTopic: $0.topic), try? verifyContextStore.get(key: $0.request.proposer.publicKey)) }
    }

    public func getPendingProposals(topic: String? = nil) -> [(proposal: Session.Proposal, context: VerifyContext?)] {
        if let topic = topic {
            return getPendingProposals().filter { $0.proposal.pairingTopic == topic }
        } else {
            return getPendingProposals()
        }
    }

}
