
import Foundation

extension SessionType {
    struct BasePermissions {
        let blockchain: BlockchainTypes.Permissions
    }
    public enum BlockchainTypes {
        struct Permissions {
            let chains: [String]
        }
        struct State {
            let accounts: [String]
        }
    }
}
