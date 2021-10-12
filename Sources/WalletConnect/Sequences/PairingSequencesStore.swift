
import Foundation

protocol PairingSequencesStore {
    func create(topic: String, sequenceState: PairingType.SequenceState)
    func getAll() -> [PairingType.SequenceState]
    func getSettled() -> [PairingType.Settled] 
    func get(topic: String) -> PairingType.SequenceState?
    func update(topic: String, newTopic: String?, sequenceState: PairingType.SequenceState)
    func delete(topic: String)
}
