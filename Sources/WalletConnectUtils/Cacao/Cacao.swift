import Foundation

/// CAIP-74 Cacao object
///
/// specs at:  https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-74.md
public struct Cacao: Codable, Equatable {
    public let h: CacaoHeader
    public let p: CacaoPayload
    public let s: CacaoSignature

    public init(h: CacaoHeader, p: CacaoPayload, s: CacaoSignature) {
        self.h = h
        self.p = p
        self.s = s
    }
}

#if DEBUG
extension Cacao {
    static func stub(
        account: Account = Account("eip155:1:0x000a10343Bcdebe21283c7172d67a9a113E819C5")!,
        resources: [String] = ["https://example.com/my-web2-claim.json"]
    ) -> Cacao {
        let header = CacaoHeader(t: "eip4361")
        let payload = CacaoPayload(
            iss: "did:pkh:\(account.absoluteString)",
            domain: "service.invalid",
            aud: "https://service.invalid/login",
            version: "1",
            nonce: "32891756",
            iat: "2024-01-29T08:54:38Z",
            nbf: nil,
            exp: nil,
            statement: "I accept the ServiceOrg Terms of Service: https://service.invalid/tos",
            requestId: nil,
            resources: resources
        )
        let signature = CacaoSignature(
            t: CacaoSignatureType.eip191,
            s: "invalid_signature",
            m: nil
        )

        return Cacao(h: header, p: payload, s: signature)
    }
}
#endif
