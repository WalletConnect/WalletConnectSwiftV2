import Foundation

struct SyncRecord: Codable & Equatable {
    let topic: String
    let store: String
    let account: Account
}
