//     

import Foundation


// Protocol for EventStorage
protocol EventStorage {
    func saveErrorTrace(_ trace: [String])
    func fetchErrorTraces() -> [[String]]
    func clearErrorTraces()
}

// Default implementation using UserDefaults
class UserDefaultsEventStorage: EventStorage {
    private let errorTracesKey = "errorTraces"

    func saveErrorTrace(_ trace: [String]) {
        var existingTraces = fetchErrorTraces()
        existingTraces.append(trace)
        if let encoded = try? JSONEncoder().encode(existingTraces) {
            UserDefaults.standard.set(encoded, forKey: errorTracesKey)
        }
    }

    func fetchErrorTraces() -> [[String]] {
        if let data = UserDefaults.standard.data(forKey: errorTracesKey),
           let traces = try? JSONDecoder().decode([[String]].self, from: data) {
            return traces
        }
        return []
    }

    func clearErrorTraces() {
        UserDefaults.standard.removeObject(forKey: errorTracesKey)
    }
}
