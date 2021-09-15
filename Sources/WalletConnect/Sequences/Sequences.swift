
import Foundation

class Sequences<T: Sequence> {
    var sequences: [T] = []
    
    func create(topic: String, sequenceState: SequenceState) {
        let sequence = T(topic: topic, sequenceState: sequenceState)
        sequences.append(sequence)
    }
    
    func get(topic: String) -> T? {
        sequences.first{$0.topic == topic}
    }

    func update(topic: String, newTopic: String? = nil, sequenceState: SequenceState) {
        guard let sequence = get(topic: topic) else {return}
        if let newTopic = newTopic {
           sequence.topic = newTopic
        }
        sequence.sequenceState = sequenceState
    }
}
