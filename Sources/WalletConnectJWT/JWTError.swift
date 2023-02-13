import Foundation

enum JWTError: Error {
    case jwtNotSigned
    case undefinedFormat
    case notBase64String
}
