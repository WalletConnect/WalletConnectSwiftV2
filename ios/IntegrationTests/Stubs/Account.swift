import Foundation
import WalletConnectUtils

extension Account {
    static func stub() -> Account {
        return Account(chainIdentifier: "eip155:1", address: "0x15bca56b6e2728aec2532df9d436bd1600e86688")!
    }
}
