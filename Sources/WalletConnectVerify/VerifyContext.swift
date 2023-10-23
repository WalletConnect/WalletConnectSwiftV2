public struct VerifyContext: Equatable, Hashable, Codable {
    public enum ValidationStatus: Codable {
        case unknown
        case valid
        case invalid
        case scam
    }
    
    public let origin: String?
    public let validation: ValidationStatus
    
    public init(origin: String?, validation: ValidationStatus) {
        self.origin = origin
        self.validation = validation
    }
}
