import Foundation
import Combine

class PendingProposalsProvider {
    
    private let proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>
    private let verifyContextStore: CodableStore<VerifyContext>
    private var publishers = Set<AnyCancellable>()
    private let pendingProposalsPublisherSubject = PassthroughSubject<[(proposal: Session.Proposal, context: VerifyContext?)], Never>()

    var pendingProposalsPublisher: AnyPublisher<[(proposal: Session.Proposal, context: VerifyContext?)], Never> {
        return pendingProposalsPublisherSubject.eraseToAnyPublisher()
    }

    internal init(
        proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>,
        verifyContextStore: CodableStore<VerifyContext>)
    {
        self.proposalPayloadsStore = proposalPayloadsStore
        self.verifyContextStore = verifyContextStore
        setUpPendingProposalsPublisher()
    }

    func setUpPendingProposalsPublisher() {
        proposalPayloadsStore.storeUpdatePublisher.sink { [unowned self] _ in
            let proposals = proposalPayloadsStore.getAll()

            let proposalsWithVerifyContext = proposals.map { ($0.request.publicRepresentation(pairingTopic: $0.topic), try? verifyContextStore.get(key: $0.request.proposer.publicKey))
            }
            pendingProposalsPublisherSubject.send(proposalsWithVerifyContext)

        }.store(in: &publishers)
    }
}
