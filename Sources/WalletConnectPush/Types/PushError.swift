import Foundation

public enum PushError: Codable, Equatable, Error {
    case rejected
    case userHasExistingSubscription
}

extension PushError: Reason {

    init?(code: Int) {
        switch code {
        case Self.rejected.code:
            self = .rejected
        default:
            return nil
        }
    }
    public var code: Int {
        switch self {
        case .rejected:
            return 15000
        case .userHasExistingSubscription:
            return 6001
        }
    }

    public var message: String {
        switch self {
        case .rejected:
            return "Push request rejected"
        case .userHasExistingSubscription:
            return "User Has Existing Subscription"
        }
    }

}
