
import Foundation

public struct NotifySubscriptionResult: Equatable, Codable {
    public let notifySubscription: NotifySubscription
    public let subscriptionAuth: String
}
