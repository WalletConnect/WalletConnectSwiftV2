
import Foundation

protocol SequencePending {
    func isEqual(to: SequencePending) -> Bool

}
extension SequencePending where Self : Equatable {
    func isEqual (to: SequencePending) -> Bool {
        return (to as? Self).flatMap({ $0 == self }) ?? false
    }
}
