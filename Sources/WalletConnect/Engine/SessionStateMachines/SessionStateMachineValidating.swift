
import Foundation

protocol SessionStateMachineValidating {
    func validateMethods(_ methods: Set<String>) -> Bool
    func validateEvents(_ events: Set<String>) -> Bool
}

extension SessionStateMachineValidating {
    func validateMethods(_ methods: Set<String>) -> Bool {
        for method in methods {
            if method.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return false
            }
        }
        return true
    }
    
    func validateEvents(_ events: Set<String>) -> Bool {
        for event in events {
            if event.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return false
            }
        }
        return true
    }
}
