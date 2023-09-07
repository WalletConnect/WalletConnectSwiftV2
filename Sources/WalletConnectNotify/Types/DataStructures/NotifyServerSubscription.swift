import Foundation

struct NotifyServerSubscription: Codable, Equatable {
    let dappUrl: String
    let account: Account
    let scope: [String]
    let symKey: String
    let expiry: Date
}
