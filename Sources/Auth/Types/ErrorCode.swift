
import Foundation

public enum ErrorCode: Codable, Equatable, Error {
    case malformedResponseParams
    case malformedRequestParams
    case messageCompromised
    case messageVerificationFailed
}
