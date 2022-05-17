
import Foundation

protocol SessionStateMachineValidating {
    func validateNamespaces(_ namespaces: Set<Namespace>) throws
}

extension SessionStateMachineValidating {
    func validateNamespaces(_ namespaces: Set<Namespace>) throws {
        try Namespace.validate(namespaces)
    }
}
