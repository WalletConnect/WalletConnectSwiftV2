import Foundation

struct SessionProposeProtocolMethod: ProtocolMethod {
    let method: String = "wc_sessionPropose"
    
    enum Tag: Int {
        case sessionPropose = 1100
        case sessionProposeResponseApprove = 1101
        case sessionProposeResponseReject = 1120
        case sessionProposeResponseAutoReject = 1121
    }

    let requestConfig: RelayConfig

    let responseConfig: RelayConfig
   
    static let defaultTtl: TimeInterval = 300
    
    private init(
        ttl: TimeInterval,
        responseTag: Tag
    ) {
        self.requestConfig = RelayConfig(
            tag: Tag.sessionPropose.rawValue,
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
        Self(ttl: ttl, responseTag: .sessionProposeResponseApprove)
    }
    
    static func responseReject(ttl: TimeInterval = Self.defaultTtl) -> Self {
        Self(ttl: ttl, responseTag: .sessionProposeResponseReject)
    }
    
    static func responseAutoReject(ttl: TimeInterval = Self.defaultTtl) -> Self {
        Self(ttl: ttl, responseTag: .sessionProposeResponseAutoReject)
    }
}
