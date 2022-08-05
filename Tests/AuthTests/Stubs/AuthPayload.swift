import Foundation
@testable import Auth

extension AuthPayload {
    static func stub() -> AuthPayload {
        AuthPayload(requestParams: RequestParams.stub(), iat: "2021-09-30T16:25:24Z")
    }
}
