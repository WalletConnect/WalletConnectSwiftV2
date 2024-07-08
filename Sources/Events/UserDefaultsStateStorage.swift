import Foundation

protocol TelemetryStateStorage {
    var telemetryEnabled: Bool { get set }
}

class UserDefaultsTelemetryStateStorage: TelemetryStateStorage {
    private let telemetryEnabledKey = "com.walletconnect.sdk.telemetryEnabled"

    var telemetryEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: telemetryEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: telemetryEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: telemetryEnabledKey)
        }
    }

    init() {
        if UserDefaults.standard.object(forKey: telemetryEnabledKey) == nil {
            // Set default value if not already set
            UserDefaults.standard.set(true, forKey: telemetryEnabledKey)
        }
    }
}

#if DEBUG
class MockUserDefaultsTelemetryStateStorage: TelemetryStateStorage {
    private var mockStorage: [String: Any] = [:]
    private let telemetryEnabledKey = "com.walletconnect.sdk.telemetryEnabled"

    var telemetryEnabled: Bool {
        get {
            if mockStorage[telemetryEnabledKey] == nil {
                return true
            }
            return mockStorage[telemetryEnabledKey] as? Bool ?? true
        }
        set {
            mockStorage[telemetryEnabledKey] = newValue
        }
    }

    init() {
        // Initialize with a default value if not already set
        if mockStorage[telemetryEnabledKey] == nil {
            mockStorage[telemetryEnabledKey] = true
        }
    }
}
#endif
