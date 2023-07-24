import Foundation

struct PushResponse: Codable {
    enum Status: String, Codable {
        case success = "SUCCESS"
        case failed = "FAILED"
    }

    let status: Status
}
