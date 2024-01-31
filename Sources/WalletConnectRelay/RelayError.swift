import Foundation

enum RelayError: Error, LocalizedError {
    case requestTimeout

    var errorDescription: String? {
        return localizedDescription
    }

    var localizedDescription: String {
        switch self {
        case .requestTimeout:
            return "Relay request timeout"
        }
    }
}
