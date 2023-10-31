import Foundation

// TODO: Integrate with WalletConnectError
public struct KeychainError: Error, LocalizedError {

    public let status: OSStatus

    public init(_ status: OSStatus) {
        self.status = status
    }

    public var errorDescription: String? {
        return "OSStatus: \(status), message: \(status.message)"
    }
}

extension KeychainError: CustomStringConvertible {

    public var description: String {
        status.message
    }
}

extension OSStatus {
    /// A human readable message for the status.
    var message: String {
        return (SecCopyErrorMessageString(self, nil) as String?) ?? String(self)
    }
}
