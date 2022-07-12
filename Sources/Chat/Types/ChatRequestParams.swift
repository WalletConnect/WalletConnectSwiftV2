import Foundation
import WalletConnectUtils

enum ChatRequestParams: Codable, Equatable {
    enum Errors: Error {
        case decoding
    }
    case invite(Invite)
    case message(Message)

    private enum CodingKeys: String, CodingKey {
        case invite
        case message
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .invite(let invite):
            try invite.encode(to: encoder)
        case .message(let message):
            try message.encode(to: encoder)
        }
    }

    init(from decoder: Decoder) throws {
        if let invite = try? Invite(from: decoder) {
            self = .invite(invite)
        } else if let massage = try? Message(from: decoder) {
            self = .message(massage)
        } else {
            throw Errors.decoding
        }
    }
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
}
