// 

import Foundation

enum RelayJSONRPC {
    enum Method: String {
        case subscribe = "waku_subscribe"
        case publish = "waku_publish"
        case subscription = "waku_subscription"
        case unsubscribe = "waku_unsubscribe"
    }
    
    struct PublishParams: Codable {
        let topic: String
        let message: String
        let ttl: Int
    }
    
    struct SubscribeParams: Codable {
        let topic: String
    }
    
    struct SubscriptionData: Decodable {
        let topic: String
        let message: String
    }
    
    struct SubscriptionParams: Decodable {
        let id: String
        let data: SubscriptionData
    }
    
    struct UnsubscribeParams: Codable {
        let id: String
        let topic: String
    }
}
