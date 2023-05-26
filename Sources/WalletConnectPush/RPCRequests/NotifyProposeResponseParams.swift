
import Foundation

struct NotifyProposeResponseParams: Codable {
    let subscriptionAuth: SubscriptionJWTPayload.Wrapper
    let subscriptionSymKey: String
}
