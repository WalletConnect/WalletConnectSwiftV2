
import Foundation

protocol Sequence: AnyObject {
    var topic: String {get set}
    var sequenceState: SequenceState {get set}
}
