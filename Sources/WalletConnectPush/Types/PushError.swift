import Foundation

public enum PushError: Codable, Equatable, Error {
    case userRejeted
    case userHasExistingSubscription
}

extension PushError: Reason {

    init?(code: Int) {
        switch code {
        case Self.userRejeted.code:
            self = .userRejeted
        default:
            return nil
        }
    }
    public var code: Int {
        switch self {
        case .userRejeted:
            return 5000
        case .userHasExistingSubscription:
            return 6001
        }
    }

    public var message: String {
        switch self {
        case .userRejeted:
            return "Push request rejected"
        case .userHasExistingSubscription:
            return "User Has Existing Subscription"
        }
    }

}
