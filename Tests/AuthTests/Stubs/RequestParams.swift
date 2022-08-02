import Foundation
@testable import Auth

extension RequestParams {
    static func stub() -> RequestParams {
        return RequestParams(domain: "", chainId: "", nonce: "", aud: "", nbf: nil, exp: nil, statement: nil, requestId: nil, resources: nil)
    }
}
