
import Foundation

protocol SequencesStore {
    func create(topic: String, sequenceState: SequenceState)
    func getAll() -> [SequenceState]
    func getSettled() -> [SequenceSettled]
    func get(topic: String) -> SequenceState?
    func update(topic: String, newTopic: String?, sequenceState: SequenceState)
    func delete(topic: String)
}
