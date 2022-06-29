// 

import Foundation

enum RelayJSONRPC {
    enum Method {
        case subscribe
        case publish
        case subscription
        case unsubscribe
    }

    struct PublishParams: Codable, Equatable {
        let topic: String
        let message: String
        let ttl: Int
        let prompt: Bool?
    }

    struct SubscribeParams: Codable, Equatable {
        let topic: String
    }

    struct SubscriptionData: Codable, Equatable {
        let topic: String
        let message: String
    }

    struct SubscriptionParams: Codable, Equatable {
        let id: String
        let data: SubscriptionData
    }

    struct UnsubscribeParams: Codable, Equatable {
        let id: String
        let topic: String
    }
}

extension RelayJSONRPC.Method {

    var prefix: String {
        return "iridium"
    }

    var name: String {
        switch self {
        case .subscribe:
            return "subscribe"
        case .publish:
            return "publish"
        case .subscription:
            return "subscription"
        case .unsubscribe:
            return "unsubscribe"
        }
    }

    var method: String {
        return "\(prefix)_\(name)"
    }
}
