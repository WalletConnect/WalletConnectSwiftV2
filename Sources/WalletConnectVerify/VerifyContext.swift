public struct VerifyContext: Equatable, Hashable, Codable {
    public enum ValidationStatus: Codable {
        case unknown
        case valid
        case invalid
        case scam
    }
    
    public let origin: String?
    public let validation: ValidationStatus
    public let verifyUrl: String
    
    public init(origin: String?, validation: ValidationStatus, verifyUrl: String) {
        self.origin = origin
        self.validation = validation
        self.verifyUrl = verifyUrl
    }
}
