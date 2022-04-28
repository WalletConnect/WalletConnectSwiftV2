
import Foundation

protocol SessionStateMachineValidating {
    func validateNamespaces(_ namespaces: Set<Namespace>) throws
}

extension SessionStateMachineValidating {
    func validateNamespaces(_ namespaces: Set<Namespace>) throws {
        for namespace in namespaces {
            for method in namespace.methods {
                if method.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    throw WalletConnectError.invalidMethod
                }
            }
            for event in namespace.events {
                if event.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    throw WalletConnectError.invalidEvent
                }
            }
        }
    }
}
