import Foundation

/// Parameters required to construct authentication request
/// for details read CAIP-74 and EIP-4361 specs
/// https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-74.md
/// https://eips.ethereum.org/EIPS/eip-4361
public struct AuthRequestParams {
    public enum Errors: Error {
        case invalidTtl
    }
    public let domain: String
    public let chains: [String]
    public let nonce: String
    public let uri: String
    public let nbf: String?
    public let exp: String?
    public let statement: String?
    public let requestId: String?
    public var resources: [String]?
    public let methods: [String]?
    public let ttl: TimeInterval

    // TTL bounds
    static let minTtl: TimeInterval = 300    // 5 minutes
    static let maxTtl: TimeInterval = 604800 // 7 days

    public init(
        domain: String,
        chains: [String],
        nonce: String,
        uri: String,
        nbf: String?,
        exp: String?,
        statement: String?,
        requestId: String?,
        resources: [String]?,
        methods: [String]?,
        ttl: TimeInterval = 3600
    ) throws {
        guard ttl >= Request.minTtl && ttl <= Request.maxTtl else {
            throw Errors.invalidTtl
        }

        self.domain = domain
        self.chains = chains
        self.nonce = nonce
        self.uri = uri
        self.nbf = nbf
        self.exp = exp
        self.statement = statement
        self.requestId = requestId
        self.resources = resources
        self.methods = methods
        self.ttl = ttl
    }

    mutating func addResource(resource: String) {
        if resources != nil {
            resources?.append(resource)
        } else {
            resources = [resource]
        }
    }
}


#if DEBUG
extension AuthRequestParams {
    static func stub(domain: String = "service.invalid",
                     chains: [String] = ["eip155:1"],
                     nonce: String = "32891756",
                     uri: String = "https://service.invalid/login",
                     nbf: String? = nil,
                     exp: String? = nil,
                     statement: String? = "I accept the ServiceOrg Terms of Service: https://service.invalid/tos",
                     requestId: String? = nil,
                     resources: [String]? = ["ipfs://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq/", "https://example.com/my-web2-claim.json"],
                     methods: [String]? = ["personal_sign", "eth_sendTransaction"]) -> AuthRequestParams {
        return try! AuthRequestParams(domain: domain,
                             chains: chains,
                             nonce: nonce,
                             uri: uri,
                             nbf: nbf,
                             exp: exp,
                             statement: statement,
                             requestId: requestId,
                             resources: resources,
                             methods: methods)
    }
}
#endif
