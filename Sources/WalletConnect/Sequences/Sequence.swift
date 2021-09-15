
import Foundation

protocol Sequence: AnyObject {
    init(topic: String, sequenceState: SequenceState)     
    var topic: String {get set}
    var sequenceState: SequenceState {get set}
}
