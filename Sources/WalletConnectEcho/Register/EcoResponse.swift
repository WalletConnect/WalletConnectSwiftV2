import Foundation

struct EchoResponse: Codable {
    enum Status: String, Codable {
        case success = "SUCCESS"
        case failed = "FAILED"
    }

    let status: Status
}
