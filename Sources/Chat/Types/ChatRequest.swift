
import Foundation
import WalletConnectUtils


enum ChatRequestParams: Codable, Equatable {
    case invite(InviteParams)
    case message(String)
}

