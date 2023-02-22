import Foundation

public struct PushResponseParams: Codable, Equatable {
    let subscriptionAuth: String
    //move to jwt pke
    let publicKey: String
}
