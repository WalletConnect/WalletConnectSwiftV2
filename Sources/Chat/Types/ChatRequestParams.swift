import Foundation
import WalletConnectUtils

enum ChatRequestParams: Codable, Equatable {
    case invite(Invite)
    case message(Message)
}

extension JSONRPCRequest {
    init(id: Int64 = JsonRpcID.generate(), params: T) where T == ChatRequestParams {
        var method: String!
        switch params {
        case .invite:
            method = "invite"
        case .message:
            method = "message"
        }
        self.init(id: id, method: method, params: params)
    }
}
