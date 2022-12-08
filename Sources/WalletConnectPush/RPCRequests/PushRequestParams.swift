import Foundation

public struct PushRequestParams: Codable {
    let publicKey: String
    let metadata: AppMetadata
    let account: Account
}
