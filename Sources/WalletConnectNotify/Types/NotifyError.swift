import Foundation

public enum NotifyError: Codable, Equatable, Error {
    case userRejeted
    case userHasExistingSubscription
    case methodUnsupported
    case registerSignatureRejected
}

extension NotifyError: Reason {

    init?(code: Int) {
        switch code {
        case Self.userRejeted.code:
            self = .userRejeted
        case Self.userHasExistingSubscription.code:
            self = .userHasExistingSubscription
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
        case .userRejeted:
            return 5000
        case .userHasExistingSubscription:
            return 6001
        case .registerSignatureRejected:
            return 1501
        }
    }

    public var message: String {
        switch self {
        case .methodUnsupported:
            return "Method Unsupported"
        case .userRejeted:
            return "Notify request rejected"
        case .userHasExistingSubscription:
            return "User Has Existing Subscription"
        case .registerSignatureRejected:
            return "Register signature rejected"
        }
    }

}
