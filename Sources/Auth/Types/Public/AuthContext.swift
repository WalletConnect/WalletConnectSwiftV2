public struct AuthContext: Equatable, Hashable {
    public enum ValidationStatus {
        case unknown
        case valid
        case invalid
    }
    
    public let origin: String?
    public let validation: ValidationStatus
    public let verifyUrl: String
}
