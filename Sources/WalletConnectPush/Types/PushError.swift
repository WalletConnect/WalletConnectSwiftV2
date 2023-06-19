import Foundation

public enum PushError: Codable, Equatable, Error {
    case userRejeted
    case userHasExistingSubscription
    case methodUnsupported
}

extension PushError: Reason {

    init?(code: Int) {
        switch code {
        case Self.userRejeted.code:
            self = .userRejeted
        case Self.methodUnsupported.code:
            self = .methodUnsupported
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
        }
    }

    public var message: String {
        switch self {
        case .methodUnsupported:
            return "Method Unsupported"
        case .userRejeted:
            return "Push request rejected"
        case .userHasExistingSubscription:
            return "User Has Existing Subscription"
        }
    }

}
