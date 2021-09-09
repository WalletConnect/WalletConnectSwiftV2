protocol SequenceEngine {
    func respond(to proposal: SequenceProposal, completion: @escaping (Result<String, Error>) -> Void)
}

protocol SequenceProposal {
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
