import Foundation

struct Message: Codable, Equatable {
    var topic: String
    let message : String
    let authorAccount: String
    let timestamp: Int64
}
