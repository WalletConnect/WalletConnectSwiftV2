
import Foundation

public struct PushSubscriptionResult: Equatable, Codable {
    let pushSubscription: PushSubscription
    let subscriptionAuth: String
}
