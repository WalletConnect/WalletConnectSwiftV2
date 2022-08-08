import Foundation
@testable import Auth

extension AuthPayload {
    static func stub(requestParams: RequestParams = RequestParams.stub()) -> AuthPayload {
        AuthPayload(requestParams: requestParams, iat: "2021-09-30T16:25:24Z")
    }
}
