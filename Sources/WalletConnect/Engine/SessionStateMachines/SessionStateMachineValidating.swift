
import Foundation

protocol SessionStateMachineValidating {
    func validateNamespaces(_ namespaces: Set<Namespace>) throws
}

extension SessionStateMachineValidating {
    func validateNamespaces(_ namespaces: Set<Namespace>) throws {
        for method in methods {
            if method.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw WalletConnectError.invalidMethod
            }
        }
    }
    
//    func validateEvents(_ events: Set<String>) throws {
//        for event in events {
//            if event.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                throw WalletConnectError.invalidEventType
//            }
//        }
//    }
}
