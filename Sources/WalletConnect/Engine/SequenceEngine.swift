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

protocol Sequence: AnyObject {
    var topic: String {get set}
    var sequenceState: SequenceState {get set}
}

class Pairing: Sequence {
    var topic: String
    var sequenceState: SequenceState
    
    internal init(topic: String, sequenceState: SequenceState) {
        self.topic = topic
        self.sequenceState = sequenceState
    }
}
