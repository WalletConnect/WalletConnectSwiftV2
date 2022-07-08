import Foundation

struct Message: Codable, Equatable {
    let message: String
    let authorAccount: String
    let timestamp: Int64
}
