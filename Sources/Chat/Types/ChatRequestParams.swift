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
            method = "wc_chatInvite"
        case .message:
            method = "wc_chatMessage"
        }
        self.init(id: id, method: method, params: params)
    }

    func encode(to encoder: Encoder) throws where T == ChatRequestParams {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(method, forKey: .method)

        switch params {
        case .invite(let value):
            try container.encode(value, forKey: .params)
        case .message(let message):
            try container.encode(message, forKey: .params)
        }


    }
}
