
import Foundation

extension SessionType {
    struct UpgradeParams: Codable, Equatable {
        let permissions: SessionPermissions
    }
}
