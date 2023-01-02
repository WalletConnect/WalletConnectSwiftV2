import Foundation

public enum PushError: Codable, Equatable, Error {
    case rejected
    case methodUnsupported
}

extension PushError: Reason {

    init?(code: Int) {
        switch code {
        case Self.rejected.code:
            self = .rejected
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
        case .rejected:
            return 15000
        }
    }

    public var message: String {
        switch self {
        case .rejected:
            return "Push request rejected"
        case .methodUnsupported:
            return "Method Unsupported"
        }
    }

}
