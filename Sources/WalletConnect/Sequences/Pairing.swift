
import Foundation

class Pairing: Sequence {
    var topic: String
    var sequenceState: SequenceState
    
    required init(topic: String, sequenceState: SequenceState) {
        self.topic = topic
        self.sequenceState = sequenceState
    }
}
