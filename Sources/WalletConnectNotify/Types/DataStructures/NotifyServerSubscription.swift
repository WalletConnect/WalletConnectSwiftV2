import Foundation

struct NotifyServerSubscription: Codable, Equatable {
    let appDomain: String
    let account: Account
    let scope: [String]
    let symKey: String
    let expiry: Date
    let appAuthenticationKey: String
}
