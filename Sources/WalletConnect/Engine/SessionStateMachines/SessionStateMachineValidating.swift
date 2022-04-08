
import Foundation

protocol SessionStateMachineValidating {
    func validateMethods(_ methods: Set<String>) throws
    func validateEvents(_ events: Set<String>) throws
}

extension SessionStateMachineValidating {
    func validateMethods(_ methods: Set<String>) throws {
        for method in methods {
            if method.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw WalletConnectError.invalidMethod
            }
        }
    }
    
    func validateEvents(_ events: Set<String>) throws {
        for event in events {
            if event.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw WalletConnectError.invalidEventType
            }
        }
    }
}
