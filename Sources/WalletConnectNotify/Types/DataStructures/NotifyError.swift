import Foundation

public enum NotifyError: Codable, Equatable, Error {
    case methodUnsupported
    case registerSignatureRejected
}

extension NotifyError: Reason {

    init?(code: Int) {
        switch code {
        case Self.methodUnsupported.code:
            self = .methodUnsupported
        case Self.registerSignatureRejected.code:
            self = .registerSignatureRejected
        default:
            return nil
        }
    }
    public var code: Int {
        switch self {
        case .methodUnsupported:
            return 10001
        case .registerSignatureRejected:
            return 1501
        }
    }

    public var message: String {
        switch self {
        case .methodUnsupported:
            return "Method Unsupported"
        case .registerSignatureRejected:
            return "Register signature rejected"
        }
    }

}
