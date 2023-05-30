
import Foundation

struct NotifyProposeParams: Codable {
    let publicKey: String
    let metadata: AppMetadata
    let account: Account
    let scope: [String]
}
