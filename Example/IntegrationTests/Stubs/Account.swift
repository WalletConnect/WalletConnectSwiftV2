import Foundation
import WalletConnectUtils

extension Account {
    static func stub() -> Account {
        return Account(chainIdentifier: "eip155:1", address: "0x724d0D2DaD3fbB0C168f947B87Fa5DBe36F1A8bf")!
    }
}
