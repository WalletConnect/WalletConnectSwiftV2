import Foundation

public enum ExternalError: Codable, Equatable, Error {
    case userRejeted
}

extension ExternalError: Reason {

    public var code: Int {
        switch self {
        case .userRejeted:
            return 2001
        }
    }

    public var message: String {
        switch self {
        case .userRejeted:
            return "Auth request rejected by user"
        }
    }
}
