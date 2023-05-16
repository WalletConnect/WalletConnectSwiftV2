import SwiftUI

private struct ProjectIdKey: EnvironmentKey {
    static let defaultValue: String = ""
}

extension EnvironmentValues {
    var projectId: String {
        get { self[ProjectIdKey.self] }
        set { self[ProjectIdKey.self] = newValue }
    }
}
