import Foundation
@testable import Auth

extension RequestParams {
    static func stub() -> RequestParams {
        return RequestParams(domain: "service.invalid",
                             chainId: "1",
                             nonce: "32891756",
                             aud: "https://service.invalid/login",
                             nbf: nil,
                             exp: nil,
                             statement: "I accept the ServiceOrg Terms of Service: https://service.invalid/tos",
                             requestId: nil,
                             resources: ["ipfs://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq/", "https://example.com/my-web2-claim.json"])
    }
}
