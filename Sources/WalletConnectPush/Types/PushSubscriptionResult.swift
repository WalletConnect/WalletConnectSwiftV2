
import Foundation

public struct PushSubscriptionResult: Equatable, Codable {
    public let pushSubscription: PushSubscription
    public let subscriptionAuth: String
}
