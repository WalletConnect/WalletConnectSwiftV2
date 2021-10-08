
import Foundation

protocol SessionSequencesStore {
    func create(topic: String, sequenceState: SessionType.SequenceState)
    func getAll() -> [SessionType.SequenceState]
    func getSettled() -> [SessionType.Settled]
    func get(topic: String) -> SessionType.SequenceState?
    func update(topic: String, newTopic: String?, sequenceState: SessionType.SequenceState)
    func delete(topic: String)
}
