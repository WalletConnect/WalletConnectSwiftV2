import Foundation

/// Parameters required to construct authentication request
/// for details read CAIP-74 and EIP-4361 specs
/// https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-74.md
/// https://eips.ethereum.org/EIPS/eip-4361
public struct RequestParams {
    public let domain: String
    public let chains: [String]
    public let nonce: String
    public let aud: String
    public let nbf: String?
    public let exp: String?
    public let statement: String?
    public let requestId: String?
    public let resources: [String]?

    public init(
        domain: String,
        chains: [String],
        nonce: String,
        aud: String,
        nbf: String?,
        exp: String?,
        statement: String?,
        requestId: String?,
        resources: [String]?
    ) {
        self.domain = domain
        self.chains = chains
        self.nonce = nonce
        self.aud = aud
        self.nbf = nbf
        self.exp = exp
        self.statement = statement
        self.requestId = requestId
        self.resources = resources
    }
}


#if DEBUG
extension RequestParams {
    static func stub(domain: String = "service.invalid",
                     chains: [String] = ["eip155:1"],
                     nonce: String = "32891756",
                     aud: String = "https://service.invalid/login",
                     nbf: String? = nil,
                     exp: String? = nil,
                     statement: String? = "I accept the ServiceOrg Terms of Service: https://service.invalid/tos",
                     requestId: String? = nil,
                     resources: [String]? = ["ipfs://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq/", "https://example.com/my-web2-claim.json"]) -> RequestParams {
        return RequestParams(domain: domain,
                             chains: chains,
                             nonce: nonce,
                             aud: aud,
                             nbf: nbf,
                             exp: exp,
                             statement: statement,
                             requestId: requestId,
                             resources: resources)
    }
}
#endif
