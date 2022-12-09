
import Foundation

enum PushError: Codable, Equatable, Error {
    case rejected
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
    var code: Int {
        switch self {
        case .rejected:
            return 15000
        }
    }

    var message: String {
        switch self {
        case .rejected:
            return "Push request rejected"
        }
    }

}
