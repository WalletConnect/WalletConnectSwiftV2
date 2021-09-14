protocol SequenceEngine {
    func respond(to proposal: PairingType.Proposal, completion: @escaping (Result<String, Error>) -> Void)
}

protocol SequenceProposal {
    var topic: String { get }
    var relay: RelayProtocolOptions { get }
}

enum SequenceStatus {
    case pending
    case proposed
    case responded
    case settled
}

protocol Sequence {
    var status: SequenceStatus {get set}
}
