import Foundation

struct SessionAuthenticatedProtocolMethod: ProtocolMethod {
    
    enum Tag: Int {
        case sessionAuthenticate = 1116
        case sessionAuthenticateResponseApprove = 1117
        case sessionAuthenticateResponseReject = 1118
        case sessionAuthenticateResponseAutoReject = 1119
    }
    
    let method: String = "wc_sessionAuthenticate"

    let requestConfig: RelayConfig
    
    let responseConfig: RelayConfig

    static let defaultTtl: TimeInterval = 300
    
    private init(
        ttl: TimeInterval,
        responseTag: Tag
    ) {
        self.requestConfig = RelayConfig(
            tag: Tag.sessionAuthenticate.rawValue,
            prompt: true,
            ttl: Int(ttl)
        )
        self.responseConfig = RelayConfig(
            tag: responseTag.rawValue,
            prompt: false,
            ttl: Int(ttl)
        )
    }
    
    static func responseApprove(ttl: TimeInterval = Self.defaultTtl) -> Self {
        Self(ttl: ttl, responseTag: .sessionAuthenticateResponseApprove)
    }
    
    static func responseReject(ttl: TimeInterval = Self.defaultTtl) -> Self {
        Self(ttl: ttl, responseTag: .sessionAuthenticateResponseReject)
    }
    
    static func responseAutoReject(ttl: TimeInterval = Self.defaultTtl) -> Self {
        Self(ttl: ttl, responseTag: .sessionAuthenticateResponseAutoReject)
    }
}
