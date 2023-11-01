import Foundation

public enum KeychainError: Error, LocalizedError {
    case itemNotFound
    case other(OSStatus)

    public init(_ status: OSStatus) {
        switch status {
        case errSecItemNotFound:
            self = .itemNotFound
        default:
            self = .other(status)
        }
    }

    public var status: OSStatus {
        switch self {
        case .itemNotFound:
            return errSecItemNotFound
        case .other(let status):
            return status
        }
    }

    public var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Keychain item not found"
        case .other(let status):
            return "OSStatus: \(status), message: \(status.message)"
        }
    }
}

extension KeychainError: CustomStringConvertible {

    public var description: String {
        return errorDescription ?? ""
    }
}

extension OSStatus {
    /// A human readable message for the status.
    var message: String {
        return (SecCopyErrorMessageString(self, nil) as String?) ?? String(self)
    }
}
